import { beforeEach, describe, expect, it } from "vitest";
import {
    addTrackToPlaylist,
    createPlaylist,
    deletePlaylist,
    getPlaylist,
    getPlaylists,
    removeTrackFromPlaylist
} from "../../../model/Playlists";

const TRACK_A = { name: "Song A", duration: "3:00", artistName: "Artist X", albumName: "Album 1", albumImage: "" };
const TRACK_B = { name: "Song B", duration: "4:00", artistName: "Artist Y", albumName: "Album 2", albumImage: "" };

beforeEach(() => {
    localStorage.clear();
});

describe("createPlaylist / getPlaylists", () => {
    it("creates an empty playlist and lists it", () => {
        const playlist = createPlaylist("Road Trip");
        expect(playlist.name).toBe("Road Trip");
        expect(playlist.tracks).toEqual([]);
        expect(getPlaylists().map(p => p.id)).toEqual([playlist.id]);
    });

    it("assigns each playlist a unique id", () => {
        const a = createPlaylist("A");
        const b = createPlaylist("B");
        expect(a.id).not.toBe(b.id);
    });
});

describe("addTrackToPlaylist", () => {
    it("adds a track and assigns it the next rank", () => {
        const playlist = createPlaylist("Mix");
        addTrackToPlaylist(playlist.id, TRACK_A);
        addTrackToPlaylist(playlist.id, TRACK_B);

        const tracks = getPlaylist(playlist.id)!.tracks;
        expect(tracks.map(t => t.name)).toEqual(["Song A", "Song B"]);
        expect(tracks.map(t => t.rank)).toEqual([1, 2]);
    });

    it("dedupes by name+artist+album and reports the result", () => {
        const playlist = createPlaylist("Mix");
        expect(addTrackToPlaylist(playlist.id, TRACK_A)).toBe(true);
        expect(addTrackToPlaylist(playlist.id, TRACK_A)).toBe(false);
        expect(getPlaylist(playlist.id)!.tracks).toHaveLength(1);
    });

    it("returns false for an unknown playlist id", () => {
        expect(addTrackToPlaylist("does-not-exist", TRACK_A)).toBe(false);
    });
});

describe("removeTrackFromPlaylist", () => {
    it("removes a track and renumbers remaining ranks", () => {
        const playlist = createPlaylist("Mix");
        addTrackToPlaylist(playlist.id, TRACK_A);
        addTrackToPlaylist(playlist.id, TRACK_B);

        removeTrackFromPlaylist(playlist.id, 0);

        const tracks = getPlaylist(playlist.id)!.tracks;
        expect(tracks.map(t => t.name)).toEqual(["Song B"]);
        expect(tracks.map(t => t.rank)).toEqual([1]);
    });
});

describe("deletePlaylist", () => {
    it("removes the playlist entirely", () => {
        const playlist = createPlaylist("Temp");
        deletePlaylist(playlist.id);
        expect(getPlaylist(playlist.id)).toBeUndefined();
        expect(getPlaylists()).toEqual([]);
    });
});
