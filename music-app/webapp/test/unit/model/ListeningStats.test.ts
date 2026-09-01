import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { getStats, recordPlay } from "../../../model/ListeningStats";

beforeEach(() => {
    localStorage.clear();
});

afterEach(() => {
    vi.useRealTimers();
});

describe("recordPlay / getStats", () => {
    it("counts total plays", () => {
        recordPlay("Artist A", "Song 1");
        recordPlay("Artist A", "Song 2");
        expect(getStats().totalPlays).toBe(2);
    });

    it("ranks top artists by play count, capped at 5", () => {
        const plays: Array<[string, number]> = [
            ["Artist A", 5], ["Artist B", 4], ["Artist C", 3],
            ["Artist D", 2], ["Artist E", 1], ["Artist F", 1]
        ];
        for (const [artist, count] of plays) {
            for (let i = 0; i < count; i++) recordPlay(artist, `Song ${i}`);
        }

        const { topArtists } = getStats();
        expect(topArtists).toHaveLength(5);
        expect(topArtists.map(a => a.name)).toEqual(["Artist A", "Artist B", "Artist C", "Artist D", "Artist E"]);
        expect(topArtists[0]).toEqual({ name: "Artist A", count: 5 });
    });

    it("computes genre breakdown percentages", () => {
        recordPlay("A", "1", "Rock");
        recordPlay("A", "2", "Rock");
        recordPlay("B", "3", "Pop");
        recordPlay("C", "4"); // no genre — excluded from breakdown, still counts toward totalPlays

        const { genreBreakdown, totalPlays } = getStats();
        expect(totalPlays).toBe(4);
        expect(genreBreakdown).toEqual([
            { genre: "Rock", count: 2, percent: 50 },
            { genre: "Pop", count: 1, percent: 25 }
        ]);
    });

    it("ignores calls missing an artist or track name", () => {
        recordPlay("", "Song");
        recordPlay("Artist", "");
        expect(getStats().totalPlays).toBe(0);
    });

    it("caps the stored event log at 2000 entries, dropping the oldest first", () => {
        for (let i = 0; i < 2005; i++) recordPlay("Artist", `Song ${i}`);
        expect(getStats().totalPlays).toBe(2000);
    });
});

describe("streak", () => {
    it("is 0 with no plays", () => {
        expect(getStats().streak).toBe(0);
    });

    it("is 1 after a play today", () => {
        vi.useFakeTimers();
        vi.setSystemTime(new Date("2026-07-16T12:00:00Z"));
        recordPlay("A", "1");
        expect(getStats().streak).toBe(1);
    });

    it("counts consecutive days ending today", () => {
        vi.useFakeTimers();

        vi.setSystemTime(new Date("2026-07-14T12:00:00Z"));
        recordPlay("A", "1");

        vi.setSystemTime(new Date("2026-07-15T12:00:00Z"));
        recordPlay("A", "2");

        vi.setSystemTime(new Date("2026-07-16T12:00:00Z"));
        recordPlay("A", "3");

        expect(getStats().streak).toBe(3);
    });

    it("resets to 0 if today has no play, even with a prior streak", () => {
        vi.useFakeTimers();

        vi.setSystemTime(new Date("2026-07-15T12:00:00Z"));
        recordPlay("A", "1");

        vi.setSystemTime(new Date("2026-07-17T12:00:00Z"));
        expect(getStats().streak).toBe(0);
    });
});
