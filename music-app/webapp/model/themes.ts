export interface AppTheme {
    id: string;
    label: string;
    primary: string;
    primaryRgb: string;
    primaryLight: string;
    primaryLightRgb: string;
    darkBg: string;
}

export const THEMES: AppTheme[] = [
    {
        id: "blue",
        label: "Ocean Blue",
        primary: "#0070F2",
        primaryRgb: "0, 112, 242",
        primaryLight: "#5AABFF",
        primaryLightRgb: "90, 171, 255",
        darkBg: "#1a1a2e"
    },
    {
        id: "purple",
        label: "Purple Night",
        primary: "#7C3AED",
        primaryRgb: "124, 58, 237",
        primaryLight: "#9D6FF7",
        primaryLightRgb: "157, 111, 247",
        darkBg: "#1a1a2e"
    },
    {
        id: "green",
        label: "Emerald",
        primary: "#059669",
        primaryRgb: "5, 150, 105",
        primaryLight: "#34D399",
        primaryLightRgb: "52, 211, 153",
        darkBg: "#0d2020"
    },
    {
        id: "red",
        label: "Sunset",
        primary: "#DC2626",
        primaryRgb: "220, 38, 38",
        primaryLight: "#F87171",
        primaryLightRgb: "248, 113, 113",
        darkBg: "#2a1212"
    },
    {
        id: "amber",
        label: "Gold",
        primary: "#D97706",
        primaryRgb: "217, 119, 6",
        primaryLight: "#FBBF24",
        primaryLightRgb: "251, 191, 36",
        darkBg: "#1a1500"
    }
];

const STORAGE_KEY = "musicApp.theme";

export function applyTheme(theme: AppTheme): void {
    const root = document.documentElement;
    root.style.setProperty("--app-primary",           theme.primary);
    root.style.setProperty("--app-primary-rgb",       theme.primaryRgb);
    root.style.setProperty("--app-primary-light",     theme.primaryLight);
    root.style.setProperty("--app-primary-light-rgb", theme.primaryLightRgb);
    root.style.setProperty("--app-dark-bg",           theme.darkBg);
    try { localStorage.setItem(STORAGE_KEY, theme.id); } catch { /* ignore */ }
}

export function loadSavedTheme(): void {
    try {
        const savedId = localStorage.getItem(STORAGE_KEY);
        applyTheme(THEMES.find(t => t.id === savedId) ?? THEMES[0]);
    } catch {
        applyTheme(THEMES[0]);
    }
}

export function getSavedThemeId(): string {
    try { return localStorage.getItem(STORAGE_KEY) ?? THEMES[0].id; }
    catch { return THEMES[0].id; }
}
