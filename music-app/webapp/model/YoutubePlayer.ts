import JSONModel from "sap/ui/model/json/JSONModel";
import { YOUTUBE_API_KEY } from "./config";
import { recordPlay } from "./ListeningStats";
import { getSimilarArtists, getArtistTopTracks, formatDuration, extractLastFmImage } from "./LastFmApi";

declare global {
    interface Window {
        onYouTubeIframeAPIReady: () => void;
        YT: {
            Player: new (elementId: string, options: YTPlayerOptions) => YTPlayer;
            PlayerState: { ENDED: number; PLAYING: number; PAUSED: number; BUFFERING: number; UNSTARTED: number };
        };
    }
}

interface YTPlayerOptions {
    height: string;
    width: string;
    videoId: string;
    playerVars: Record<string, number | string>;
    events: { onReady?: () => void; onStateChange?: (e: { data: number }) => void };
}

interface YTPlayer {
    loadVideoById(videoId: string): void;
    playVideo(): void;
    pauseVideo(): void;
    seekTo(seconds: number, allowSeekAhead: boolean): void;
    getCurrentTime(): number;
    getDuration(): number;
    getPlayerState(): number;
    setVolume(volume: number): void;
    getVolume(): number;
}

interface QueueItem {
    rank: number;
    name: string;
    duration: string;
    videoId?: string | null;
    artistName: string;
    albumName: string;
    albumImage: string;
    genre?: string;
}

function formatTime(seconds: number): string {
    if (!seconds || isNaN(seconds)) return "0:00";
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s.toString().padStart(2, "0")}`;
}

let ytPlayer: YTPlayer | null = null;
let model: JSONModel | null = null;
let progressTimer: ReturnType<typeof setInterval> | null = null;
let ytReady = false;
let pendingVideoId: string | null = null;

const DEFAULT_TITLE = document.title;

function updateMediaSession(track: { name: string; artistName: string; albumName: string; image?: string } | null): void {
    document.title = track ? `${track.name} · ${track.artistName} — ${DEFAULT_TITLE}` : DEFAULT_TITLE;

    if (!("mediaSession" in navigator)) return;

    navigator.mediaSession.metadata = track
        ? new MediaMetadata({
            title: track.name,
            artist: track.artistName,
            album: track.albumName,
            artwork: track.image ? [{ src: track.image, sizes: "300x300", type: "image/jpeg" }] : []
        })
        : null;
}

function setupMediaSessionHandlers(): void {
    if (!("mediaSession" in navigator)) return;

    navigator.mediaSession.setActionHandler("play", () => ytPlayer?.playVideo());
    navigator.mediaSession.setActionHandler("pause", () => ytPlayer?.pauseVideo());
    navigator.mediaSession.setActionHandler("previoustrack", () => skipToPrev());
    navigator.mediaSession.setActionHandler("nexttrack", () => skipToNext());
    navigator.mediaSession.setActionHandler("seekto", (details) => {
        if (details.seekTime != null) ytPlayer?.seekTo(details.seekTime, true);
    });
}

export function initYoutubePlayer(playerModel: JSONModel): void {
    model = playerModel;
    setupMediaSessionHandlers();
    loadYouTubeScript();
}

function loadYouTubeScript(): void {
    if (document.getElementById("yt-iframe-api")) return;
    const tag = document.createElement("script");
    tag.id = "yt-iframe-api";
    tag.src = "https://www.youtube.com/iframe_api";
    document.head.appendChild(tag);

    window.onYouTubeIframeAPIReady = () => {
        const container = document.createElement("div");
        container.id = "yt-player-host";
        container.style.cssText = "position:fixed;bottom:-200px;left:-200px;width:1px;height:1px;overflow:hidden;pointer-events:none;";
        document.body.appendChild(container);

        ytPlayer = new window.YT.Player("yt-player-host", {
            height: "1",
            width: "1",
            videoId: "",
            playerVars: { autoplay: 0, controls: 0, rel: 0 },
            events: {
                onReady: () => {
                    ytReady = true;
                    const savedVol = parseInt(localStorage.getItem("musicApp.volume") ?? "80", 10);
                    ytPlayer?.setVolume(savedVol);
                    model?.setProperty("/volume", savedVol);
                    if (pendingVideoId) {
                        loadAndPlay(pendingVideoId);
                        pendingVideoId = null;
                    }
                },
                onStateChange: (e) => {
                    const S = window.YT.PlayerState;
                    if (e.data === S.PLAYING) {
                        model?.setProperty("/isPlaying", true);
                        if ("mediaSession" in navigator) navigator.mediaSession.playbackState = "playing";
                        startProgressTimer();
                    } else if (e.data === S.PAUSED) {
                        model?.setProperty("/isPlaying", false);
                        if ("mediaSession" in navigator) navigator.mediaSession.playbackState = "paused";
                    } else if (e.data === S.ENDED) {
                        autoAdvance();
                    }
                }
            }
        });
    };
}

function startProgressTimer(): void {
    if (progressTimer) clearInterval(progressTimer);
    progressTimer = setInterval(() => {
        if (!ytPlayer || !model) return;
        const current = ytPlayer.getCurrentTime();
        const total = ytPlayer.getDuration();
        model.setProperty("/progress", current);
        model.setProperty("/duration", total);
        model.setProperty("/progressPercent", total > 0 ? (current / total) * 100 : 0);
        model.setProperty("/progressTime", formatTime(current));
        model.setProperty("/durationTime", formatTime(total));
    }, 500);
}

async function searchYouTube(artistName: string, trackName: string): Promise<string | null> {
    if (!YOUTUBE_API_KEY) {
        console.warn("YoutubePlayer: API key not set in webapp/model/YoutubePlayer.ts");
        return null;
    }
    try {
        const q = encodeURIComponent(`${artistName} ${trackName} official audio`);
        const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${q}&type=video&videoCategoryId=10&maxResults=5&key=${YOUTUBE_API_KEY}`;
        const res = await fetch(url);
        const data = await res.json();
        return (data.items?.[0]?.id?.videoId as string) ?? null;
    } catch {
        return null;
    }
}

function loadAndPlay(videoId: string): void {
    if (!ytPlayer) return;
    ytPlayer.loadVideoById(videoId);
}

async function playAtIndex(index: number): Promise<void> {
    if (!model) return;
    const queue = model.getProperty("/queue") as QueueItem[];
    if (index < 0 || index >= queue.length) return;

    model.setProperty("/queueIndex", index);
    model.setProperty("/isLoading", true);

    const item = queue[index];
    model.setProperty("/currentTrack", {
        name: item.name,
        artistName: item.artistName,
        albumName: item.albumName,
        rank: item.rank,
        duration: item.duration,
        image: item.albumImage
    });
    updateMediaSession({ name: item.name, artistName: item.artistName, albumName: item.albumName, image: item.albumImage });

    let videoId = item.videoId;
    if (videoId === undefined) {
        videoId = await searchYouTube(item.artistName, item.name);
        const updatedQueue = [...(model.getProperty("/queue") as QueueItem[])];
        updatedQueue[index] = { ...updatedQueue[index], videoId };
        model.setProperty("/queue", updatedQueue);
    }

    model.setProperty("/isLoading", false);

    if (!videoId) {
        skipToNext();
        return;
    }

    recordPlay(item.artistName, item.name, item.genre);

    if (ytReady && ytPlayer) {
        loadAndPlay(videoId);
    } else {
        pendingVideoId = videoId;
    }
}

export async function playQueue(
    tracks: Array<{ rank: number; name: string; duration: string }>,
    artistName: string,
    albumName: string,
    albumImage: string,
    startIndex: number = 0,
    genre?: string
): Promise<void> {
    const queue: QueueItem[] = tracks.map(t => ({ ...t, artistName, albumName, albumImage, genre }));
    await playCustomQueue(queue, startIndex);
}

export async function playCustomQueue(
    tracks: Array<{ rank: number; name: string; duration: string; artistName: string; albumName: string; albumImage: string }>,
    startIndex: number = 0
): Promise<void> {
    if (!model) return;
    model.setProperty("/queue", tracks.map(t => ({ ...t })));
    model.setProperty("/visible", true);
    await playAtIndex(startIndex);
}

export function togglePlayPause(): void {
    if (!ytPlayer) return;
    const state = ytPlayer.getPlayerState();
    if (state === window.YT?.PlayerState?.PLAYING) {
        ytPlayer.pauseVideo();
    } else {
        ytPlayer.playVideo();
    }
}

function randomIndexExcluding(length: number, exclude: number): number {
    if (length === 1) return 0;
    let next: number;
    do { next = Math.floor(Math.random() * length); } while (next === exclude);
    return next;
}

async function fetchRadioTracks(seedArtistName: string, existingQueue: QueueItem[]): Promise<QueueItem[]> {
    try {
        const similar = await getSimilarArtists(seedArtistName);
        const existingArtists = new Set(existingQueue.map(t => t.artistName));
        const candidate = similar.find((a: any) => !existingArtists.has(a.name)) ?? similar[0];
        if (!candidate?.name) return [];

        const topTracks = await getArtistTopTracks(candidate.name);
        const existingTrackKeys = new Set(existingQueue.map(t => `${t.artistName}|${t.name}`));

        return topTracks
            .filter((t: any) => !existingTrackKeys.has(`${candidate.name}|${t.name}`))
            .slice(0, 5)
            .map((t: any, i: number) => ({
                rank: existingQueue.length + i + 1,
                name: t.name,
                duration: formatDuration(Number(t.duration)),
                artistName: candidate.name,
                albumName: "Radio",
                albumImage: extractLastFmImage(t.image)
            }));
    } catch {
        return [];
    }
}

async function extendQueueWithRadio(): Promise<void> {
    if (!model) return;
    const queue = model.getProperty("/queue") as QueueItem[];
    const lastTrack = queue[queue.length - 1];
    if (!lastTrack) return;

    model.setProperty("/isLoading", true);
    const newTracks = await fetchRadioTracks(lastTrack.artistName, queue);

    if (!newTracks.length) {
        model.setProperty("/isLoading", false);
        ytPlayer?.pauseVideo();
        model.setProperty("/isPlaying", false);
        if (progressTimer) clearInterval(progressTimer);
        return;
    }

    const startIndex = queue.length;
    model.setProperty("/queue", [...queue, ...newTracks]);
    await playAtIndex(startIndex);
}

function autoAdvance(): void {
    if (!model) return;
    const repeatMode = model.getProperty("/repeatMode") as string;
    if (repeatMode === "one") {
        playAtIndex(model.getProperty("/queueIndex") as number);
        return;
    }
    skipToNext();
}

export function skipToNext(): void {
    if (!model) return;
    const queue = model.getProperty("/queue") as QueueItem[];
    const index = model.getProperty("/queueIndex") as number;
    const repeatMode = model.getProperty("/repeatMode") as string;
    const shuffleOn = model.getProperty("/shuffleOn") as boolean;

    if (shuffleOn && queue.length > 1) {
        playAtIndex(randomIndexExcluding(queue.length, index));
        return;
    }

    if (index < queue.length - 1) {
        playAtIndex(index + 1);
    } else if (repeatMode === "all") {
        playAtIndex(0);
    } else if (model.getProperty("/radioOn")) {
        extendQueueWithRadio();
    } else {
        ytPlayer?.pauseVideo();
        model.setProperty("/isPlaying", false);
        if (progressTimer) clearInterval(progressTimer);
    }
}

export function skipToPrev(): void {
    if (!model || !ytPlayer) return;
    const current = ytPlayer.getCurrentTime();
    if (current > 3) {
        ytPlayer.seekTo(0, true);
        return;
    }
    const index = model.getProperty("/queueIndex") as number;
    if (index > 0) playAtIndex(index - 1);
}

export function seekTo(percent: number): void {
    if (!ytPlayer) return;
    const duration = ytPlayer.getDuration();
    ytPlayer.seekTo((percent / 100) * duration, true);
}

export function jumpToTrack(index: number): void {
    playAtIndex(index);
}

export function moveQueueItem(fromIndex: number, toIndex: number): void {
    if (!model) return;
    const queue = [...(model.getProperty("/queue") as QueueItem[])];
    if (fromIndex < 0 || fromIndex >= queue.length || toIndex < 0 || toIndex >= queue.length || fromIndex === toIndex) return;

    const currentIndex = model.getProperty("/queueIndex") as number;

    const [moved] = queue.splice(fromIndex, 1);
    queue.splice(toIndex, 0, moved);
    model.setProperty("/queue", queue);

    let newCurrentIndex = currentIndex;
    if (fromIndex === currentIndex) {
        newCurrentIndex = toIndex;
    } else if (fromIndex < currentIndex && toIndex >= currentIndex) {
        newCurrentIndex = currentIndex - 1;
    } else if (fromIndex > currentIndex && toIndex <= currentIndex) {
        newCurrentIndex = currentIndex + 1;
    }
    if (newCurrentIndex !== currentIndex) {
        model.setProperty("/queueIndex", newCurrentIndex);
    }
}

export function removeFromQueue(index: number): void {
    if (!model) return;
    const queue = [...(model.getProperty("/queue") as QueueItem[])];
    const currentIndex = model.getProperty("/queueIndex") as number;

    queue.splice(index, 1);
    model.setProperty("/queue", queue);

    if (index === currentIndex) {
        if (queue.length === 0) {
            ytPlayer?.pauseVideo();
            model.setProperty("/isPlaying", false);
            model.setProperty("/visible", false);
            model.setProperty("/currentTrack", null);
            model.setProperty("/queueIndex", -1);
            updateMediaSession(null);
            if (progressTimer) clearInterval(progressTimer);
        } else {
            playAtIndex(Math.min(index, queue.length - 1));
        }
    } else if (index < currentIndex) {
        model.setProperty("/queueIndex", currentIndex - 1);
    }
}

export function setVolume(volume: number): void {
    const clamped = Math.max(0, Math.min(100, Math.round(volume)));
    ytPlayer?.setVolume(clamped);
    model?.setProperty("/volume", clamped);
    try { localStorage.setItem("musicApp.volume", String(clamped)); } catch { /* storage unavailable */ }
}
