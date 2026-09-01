import { LASTFM_API_KEY as API_KEY } from "./config";

const BASE = "https://ws.audioscrobbler.com/2.0";

export async function getTopArtists(): Promise<any[]> {
    const res = await fetch(`${BASE}/?method=chart.gettopartists&api_key=${API_KEY}&format=json&limit=20`);
    const data = await res.json();
    return data.artists?.artist ?? [];
}

export async function searchArtists(query: string): Promise<any[]> {
    const res = await fetch(`${BASE}/?method=artist.search&artist=${encodeURIComponent(query)}&api_key=${API_KEY}&format=json&limit=20`);
    const data = await res.json();
    return data.results?.artistmatches?.artist ?? [];
}

export async function getArtistsByTag(tag: string): Promise<any[]> {
    const res = await fetch(`${BASE}/?method=tag.gettopartists&tag=${encodeURIComponent(tag)}&api_key=${API_KEY}&format=json&limit=20`);
    const data = await res.json();
    return data.topartists?.artist ?? [];
}

export async function getTopAlbums(artistName: string): Promise<any[]> {
    const res = await fetch(`${BASE}/?method=artist.gettopalbums&artist=${encodeURIComponent(artistName)}&api_key=${API_KEY}&format=json&limit=15`);
    const data = await res.json();
    return data.topalbums?.album ?? [];
}

export async function getArtistInfo(artistName: string): Promise<any> {
    const res = await fetch(`${BASE}/?method=artist.getinfo&artist=${encodeURIComponent(artistName)}&api_key=${API_KEY}&format=json`);
    const data = await res.json();
    return data.artist ?? null;
}

export async function getSimilarArtists(artistName: string): Promise<any[]> {
    const res = await fetch(`${BASE}/?method=artist.getsimilar&artist=${encodeURIComponent(artistName)}&api_key=${API_KEY}&format=json&limit=8`);
    const data = await res.json();
    return data.similarartists?.artist ?? [];
}

export async function getArtistTopTracks(artistName: string): Promise<any[]> {
    const res = await fetch(`${BASE}/?method=artist.gettoptracks&artist=${encodeURIComponent(artistName)}&api_key=${API_KEY}&format=json&limit=10`);
    const data = await res.json();
    return data.toptracks?.track ?? [];
}

export async function getAlbumInfo(artistName: string, albumName: string): Promise<any> {
    const res = await fetch(`${BASE}/?method=album.getinfo&artist=${encodeURIComponent(artistName)}&album=${encodeURIComponent(albumName)}&api_key=${API_KEY}&format=json`);
    const data = await res.json();
    return data.album ?? null;
}

export function formatDuration(seconds: number): string {
    if (!seconds) return "--:--";
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, "0")}`;
}

export function stripHtml(html: string): string {
    return html
        .replace(/<a[^>]*>.*?<\/a>/gi, "")
        .replace(/<[^>]+>/g, "")
        .replace(/\s{2,}/g, " ")
        .trim();
}

export function stripHtmlPreserveParagraphs(html: string): string {
    return html
        .replace(/<a[^>]*>.*?<\/a>/gi, "")
        .replace(/<\/p>|<br\s*\/?>/gi, "\n")
        .replace(/<p[^>]*>/gi, "")
        .replace(/<[^>]+>/g, "")
        .replace(/[ \t]{2,}/g, " ")
        .replace(/\n{3,}/g, "\n\n")
        .trim();
}

export function extractLastFmImage(images: Array<{ size: string; "#text": string }> | undefined): string {
    return images?.find(img => img.size === "extralarge")?.["#text"]
        ?? images?.find(img => img.size === "large")?.["#text"]
        ?? "";
}

export function extractYear(published: string): string {
    return published?.match(/\d{4}/)?.[0] ?? "";
}

export function toArray<T>(value: T | T[]): T[] {
    if (!value) return [];
    return Array.isArray(value) ? value : [value];
}
