const BASE = "https://lrclib.net/api";

export interface LyricLine {
    time: number;
    text: string;
}

export interface LyricsResult {
    synced: LyricLine[] | null;
    plain: string | null;
}

export function parseLrc(lrc: string): LyricLine[] {
    const lineRe = /\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/;
    const lines: LyricLine[] = [];

    for (const raw of lrc.split("\n")) {
        const m = lineRe.exec(raw);
        if (!m) continue;
        const text = m[4].trim();
        if (!text) continue;

        const minutes = parseInt(m[1], 10);
        const seconds = parseInt(m[2], 10);
        const millis = parseInt(m[3].padEnd(3, "0").slice(0, 3), 10);
        lines.push({ time: minutes * 60 + seconds + millis / 1000, text });
    }

    return lines.sort((a, b) => a.time - b.time);
}

export async function getLyrics(artist: string, track: string, album?: string): Promise<LyricsResult> {
    try {
        const params = new URLSearchParams({ artist_name: artist, track_name: track });
        if (album) params.set("album_name", album);

        const res = await fetch(`${BASE}/get?${params.toString()}`);
        if (!res.ok) return { synced: null, plain: null };
        const data = await res.json();

        const synced = typeof data.syncedLyrics === "string" && data.syncedLyrics.trim()
            ? parseLrc(data.syncedLyrics)
            : null;
        const plain = typeof data.plainLyrics === "string" && data.plainLyrics.trim()
            ? data.plainLyrics.trim()
            : null;

        return { synced: synced?.length ? synced : null, plain };
    } catch {
        return { synced: null, plain: null };
    }
}
