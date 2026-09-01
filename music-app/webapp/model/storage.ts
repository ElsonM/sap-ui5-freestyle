export function readJSON<T>(key: string, fallback: T): T {
    try {
        const stored = localStorage.getItem(key);
        return stored ? JSON.parse(stored) : fallback;
    } catch {
        return fallback;
    }
}

export function writeJSON(key: string, value: unknown): void {
    try {
        localStorage.setItem(key, JSON.stringify(value));
    } catch { /* storage unavailable */ }
}

export function readFlag(key: string, fallback = false): boolean {
    try {
        const stored = localStorage.getItem(key);
        return stored === null ? fallback : stored === "true";
    } catch {
        return fallback;
    }
}

export function writeFlag(key: string, value: boolean): void {
    try {
        localStorage.setItem(key, String(value));
    } catch { /* storage unavailable */ }
}
