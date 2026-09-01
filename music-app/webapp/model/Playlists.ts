import { readJSON, writeJSON } from "./storage";

export interface PlaylistTrack {
    rank: number;
    name: string;
    duration: string;
    artistName: string;
    albumName: string;
    albumImage: string;
}

export interface Playlist {
    id: string;
    name: string;
    tracks: PlaylistTrack[];
}

const STORAGE_KEY = "musicApp.playlists";

function load(): Playlist[] {
    return readJSON<Playlist[]>(STORAGE_KEY, []);
}

function save(playlists: Playlist[]): void {
    writeJSON(STORAGE_KEY, playlists);
}

export function getPlaylists(): Playlist[] {
    return load();
}

export function getPlaylist(id: string): Playlist | undefined {
    return load().find(p => p.id === id);
}

export function createPlaylist(name: string): Playlist {
    const playlists = load();
    const playlist: Playlist = {
        id: `pl_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
        name,
        tracks: []
    };
    playlists.push(playlist);
    save(playlists);
    return playlist;
}

export function deletePlaylist(id: string): void {
    save(load().filter(p => p.id !== id));
}

export function addTrackToPlaylist(playlistId: string, track: Omit<PlaylistTrack, "rank">): boolean {
    const playlists = load();
    const playlist = playlists.find(p => p.id === playlistId);
    if (!playlist) return false;

    const exists = playlist.tracks.some(t =>
        t.name === track.name && t.artistName === track.artistName && t.albumName === track.albumName);
    if (exists) return false;

    playlist.tracks.push({ ...track, rank: playlist.tracks.length + 1 });
    save(playlists);
    return true;
}

export function removeTrackFromPlaylist(playlistId: string, index: number): void {
    const playlists = load();
    const playlist = playlists.find(p => p.id === playlistId);
    if (!playlist) return;

    playlist.tracks.splice(index, 1);
    playlist.tracks.forEach((t, i) => { t.rank = i + 1; });
    save(playlists);
}
