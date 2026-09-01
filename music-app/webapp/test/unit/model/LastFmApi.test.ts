import { describe, expect, it } from "vitest";
import {
    extractLastFmImage,
    extractYear,
    formatDuration,
    stripHtml,
    stripHtmlPreserveParagraphs,
    toArray
} from "../../../model/LastFmApi";

describe("formatDuration", () => {
    it("formats seconds as m:ss", () => {
        expect(formatDuration(65)).toBe("1:05");
        expect(formatDuration(600)).toBe("10:00");
    });

    it("returns a placeholder for falsy input", () => {
        expect(formatDuration(0)).toBe("--:--");
        expect(formatDuration(NaN)).toBe("--:--");
    });
});

describe("stripHtml", () => {
    it("removes links and tags, collapsing whitespace", () => {
        expect(stripHtml("Hello <b>world</b>  <a href=\"x\">link</a>")).toBe("Hello world");
    });
});

describe("stripHtmlPreserveParagraphs", () => {
    it("turns paragraph breaks into newlines and strips links/tags", () => {
        const html = "<p>Para one.</p><p>Para two <a href=\"x\">link</a>.</p>";
        expect(stripHtmlPreserveParagraphs(html)).toBe("Para one.\nPara two .");
    });
});

describe("extractYear", () => {
    it("pulls the first 4-digit year out of a date string", () => {
        expect(extractYear("07 Jan 2022, 00:00")).toBe("2022");
    });

    it("returns an empty string when there's no year", () => {
        expect(extractYear("")).toBe("");
        expect(extractYear(undefined as unknown as string)).toBe("");
    });
});

describe("toArray", () => {
    it("wraps a single item in an array", () => {
        expect(toArray({ a: 1 })).toEqual([{ a: 1 }]);
    });

    it("passes an array through unchanged", () => {
        expect(toArray([1, 2, 3])).toEqual([1, 2, 3]);
    });

    it("returns an empty array for null/undefined", () => {
        expect(toArray(undefined as any)).toEqual([]);
        expect(toArray(null as any)).toEqual([]);
    });
});

describe("extractLastFmImage", () => {
    it("prefers extralarge over large", () => {
        const images = [
            { size: "small", "#text": "small.jpg" },
            { size: "large", "#text": "large.jpg" },
            { size: "extralarge", "#text": "extralarge.jpg" }
        ];
        expect(extractLastFmImage(images)).toBe("extralarge.jpg");
    });

    it("falls back to large when extralarge is missing", () => {
        const images = [{ size: "small", "#text": "small.jpg" }, { size: "large", "#text": "large.jpg" }];
        expect(extractLastFmImage(images)).toBe("large.jpg");
    });

    it("returns an empty string when neither size is present", () => {
        expect(extractLastFmImage([{ size: "small", "#text": "small.jpg" }])).toBe("");
        expect(extractLastFmImage(undefined)).toBe("");
    });
});
