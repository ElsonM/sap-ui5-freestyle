import JSONModel from "sap/ui/model/json/JSONModel";

let audio: HTMLAudioElement | null = null;
let model: JSONModel | null = null;

interface QueueItem {
    rank: number;
    name: string;
    duration: string;
    previewUrl?: string | null;
    artistName: string;
    albumName: string;
}

export function initAudioPlayer(playerModel: JSONModel): void {
    model = playerModel;
    audio = new Audio();

    audio.addEventListener("timeupdate", () => {
        if (!model || !audio) return;
        const pct = audio.duration ? (audio.currentTime / audio.duration) * 100 : 0;
        model.setProperty("/progress", audio.currentTime);
        model.setProperty("/progressPercent", pct);
    });

    audio.addEventListener("loadedmetadata", () => {
        if (!model || !audio) return;
        model.setProperty("/duration", audio.duration);
    });

    audio.addEventListener("play", () => model?.setProperty("/isPlaying", true));
    audio.addEventListener("pause", () => model?.setProperty("/isPlaying", false));
    audio.addEventListener("ended", () => skipToNext());
    audio.addEventListener("error", () => {
        model?.setProperty("/isLoading", false);
        skipToNext();
    });
}

async function fetchPreviewUrl(artistName: string, trackName: string): Promise<string | null> {
    try {
        const term = encodeURIComponent(`${artistName} ${trackName}`);
        const res = await fetch(`https://itunes.apple.com/search?term=${term}&media=music&limit=5&country=US`);
        const data = await res.json();
        const results: any[] = data.results ?? [];
        const best = results.find((r: any) =>
            r.artistName?.toLowerCase().includes(artistName.toLowerCase()) ||
            artistName.toLowerCase().includes(r.artistName?.toLowerCase() ?? "")
        ) ?? results[0];
        return best?.previewUrl ?? null;
    } catch {
        return null;
    }
}

async function playAtIndex(index: number): Promise<void> {
    if (!model || !audio) return;
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
        duration: item.duration
    });

    let previewUrl = item.previewUrl ?? null;
    if (previewUrl === undefined || previewUrl === null) {
        previewUrl = await fetchPreviewUrl(item.artistName, item.name);
        const updatedQueue = [...(model.getProperty("/queue") as QueueItem[])];
        updatedQueue[index] = { ...updatedQueue[index], previewUrl };
        model.setProperty("/queue", updatedQueue);
    }

    model.setProperty("/isLoading", false);

    if (previewUrl) {
        audio.src = previewUrl;
        audio.play().catch(() => { /* autoplay policy */ });
    } else {
        skipToNext();
    }
}

export async function playQueue(
    tracks: Array<{ rank: number; name: string; duration: string }>,
    artistName: string,
    albumName: string,
    startIndex: number = 0
): Promise<void> {
    if (!model) return;
    const queue: QueueItem[] = tracks.map(t => ({ ...t, artistName, albumName }));
    model.setProperty("/queue", queue);
    model.setProperty("/visible", true);
    await playAtIndex(startIndex);
}

export function togglePlayPause(): void {
    if (!audio) return;
    if (audio.paused) {
        audio.play().catch(() => { /* autoplay policy */ });
    } else {
        audio.pause();
    }
}

export function skipToNext(): void {
    if (!model) return;
    const queue = model.getProperty("/queue") as QueueItem[];
    const index = model.getProperty("/queueIndex") as number;
    if (index < queue.length - 1) {
        playAtIndex(index + 1);
    } else {
        model.setProperty("/isPlaying", false);
    }
}

export function skipToPrev(): void {
    if (!model) return;
    const index = model.getProperty("/queueIndex") as number;
    if (index > 0) {
        playAtIndex(index - 1);
    }
}

export function seekTo(percent: number): void {
    if (!audio || !audio.duration) return;
    audio.currentTime = (percent / 100) * audio.duration;
}
