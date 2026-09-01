import { beforeEach, describe, expect, it } from "vitest";
import { readFlag, readJSON, writeFlag, writeJSON } from "../../../model/storage";

beforeEach(() => {
    localStorage.clear();
});

describe("readJSON / writeJSON", () => {
    it("round-trips an object through localStorage", () => {
        writeJSON("key", { a: 1, b: [1, 2, 3] });
        expect(readJSON("key", null)).toEqual({ a: 1, b: [1, 2, 3] });
    });

    it("returns the fallback when the key is missing", () => {
        expect(readJSON("missing", { default: true })).toEqual({ default: true });
    });

    it("returns the fallback when the stored value is corrupt JSON", () => {
        localStorage.setItem("corrupt", "{not json");
        expect(readJSON("corrupt", [])).toEqual([]);
    });
});

describe("readFlag / writeFlag", () => {
    it("round-trips true and false", () => {
        writeFlag("flag", true);
        expect(readFlag("flag")).toBe(true);

        writeFlag("flag", false);
        expect(readFlag("flag")).toBe(false);
    });

    it("returns the fallback when unset", () => {
        expect(readFlag("unset")).toBe(false);
        expect(readFlag("unset", true)).toBe(true);
    });
});
