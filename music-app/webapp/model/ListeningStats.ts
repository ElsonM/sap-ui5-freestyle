import { readJSON, writeJSON } from "./storage";

interface PlayEvent {
    artistName: string;
    trackName: string;
    genre?: string;
    ts: number;
}

export interface ArtistStat {
    name: string;
    count: number;
}

export interface GenreStat {
    genre: string;
    count: number;
    percent: number;
}

export interface ListeningStats {
    totalPlays: number;
    topArtists: ArtistStat[];
    genreBreakdown: GenreStat[];
    streak: number;
}

const STORAGE_KEY = "musicApp.listeningStats";
const MAX_EVENTS = 2000;

function loadEvents(): PlayEvent[] {
    return readJSON<PlayEvent[]>(STORAGE_KEY, []);
}

export function recordPlay(artistName: string, trackName: string, genre?: string): void {
    if (!artistName || !trackName) return;
    const events = loadEvents();
    events.push({ artistName, trackName, genre: genre || undefined, ts: Date.now() });
    writeJSON(STORAGE_KEY, events.slice(-MAX_EVENTS));
}

function computeStreak(daysPlayed: Set<string>): number {
    let streak = 0;
    const cursor = new Date();
    while (daysPlayed.has(cursor.toDateString())) {
        streak++;
        cursor.setDate(cursor.getDate() - 1);
    }
    return streak;
}

export function getStats(): ListeningStats {
    const events = loadEvents();
    const totalPlays = events.length;

    const artistCounts = new Map<string, number>();
    const genreCounts = new Map<string, number>();
    const daysPlayed = new Set<string>();

    for (const e of events) {
        artistCounts.set(e.artistName, (artistCounts.get(e.artistName) ?? 0) + 1);
        if (e.genre) genreCounts.set(e.genre, (genreCounts.get(e.genre) ?? 0) + 1);
        daysPlayed.add(new Date(e.ts).toDateString());
    }

    const topArtists = [...artistCounts.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name, count]) => ({ name, count }));

    const genreBreakdown = [...genreCounts.entries()]
        .sort((a, b) => b[1] - a[1])
        .map(([genre, count]) => ({ genre, count, percent: Math.round((count / totalPlays) * 100) }));

    return {
        totalPlays,
        topArtists,
        genreBreakdown,
        streak: computeStreak(daysPlayed)
    };
}
