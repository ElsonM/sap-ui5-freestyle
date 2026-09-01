import { afterEach, describe, expect, it, vi } from "vitest";
import { getLyrics, parseLrc } from "../../../model/LyricsApi";

afterEach(() => {
    vi.unstubAllGlobals();
});

describe("parseLrc", () => {
    it("parses timestamps and text", () => {
        const lrc = "[00:12.34]First line\n[01:05.500]Second line";
        expect(parseLrc(lrc)).toEqual([
            { time: 12.34, text: "First line" },
            { time: 65.5, text: "Second line" }
        ]);
    });

    it("handles 2-digit centisecond timestamps", () => {
        expect(parseLrc("[00:05.12]Hi")).toEqual([{ time: 5.12, text: "Hi" }]);
    });

    it("skips malformed or empty lines", () => {
        const lrc = "[00:01.00]\nnot a timestamp line\n[00:02.00]Real line";
        expect(parseLrc(lrc)).toEqual([{ time: 2, text: "Real line" }]);
    });

    it("sorts lines by time even if the source is out of order", () => {
        const lrc = "[00:10.00]Second\n[00:01.00]First";
        expect(parseLrc(lrc).map(l => l.text)).toEqual(["First", "Second"]);
    });

    it("returns an empty array for lyrics with no timed lines", () => {
        expect(parseLrc("just plain text, no timestamps")).toEqual([]);
    });
});

describe("getLyrics", () => {
    it("returns synced lines when syncedLyrics is present", async () => {
        vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
            ok: true,
            json: async () => ({ syncedLyrics: "[00:01.00]Line one", plainLyrics: "Line one" })
        }));

        const result = await getLyrics("Artist", "Track");
        expect(result.synced).toEqual([{ time: 1, text: "Line one" }]);
        expect(result.plain).toBe("Line one");
    });

    it("falls back to plain-only when there's no synced lyrics", async () => {
        vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
            ok: true,
            json: async () => ({ syncedLyrics: "", plainLyrics: "Just plain text" })
        }));

        const result = await getLyrics("Artist", "Track");
        expect(result.synced).toBeNull();
        expect(result.plain).toBe("Just plain text");
    });

    it("returns nulls when the response is not ok", async () => {
        vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: false }));

        const result = await getLyrics("Artist", "Track");
        expect(result).toEqual({ synced: null, plain: null });
    });

    it("returns nulls when fetch throws", async () => {
        vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("network down")));

        const result = await getLyrics("Artist", "Track");
        expect(result).toEqual({ synced: null, plain: null });
    });
});
