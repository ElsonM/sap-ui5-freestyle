import Button from "sap/m/Button";
import List from "sap/m/List";
import Controller from "sap/ui/core/mvc/Controller";
import Fragment from "sap/ui/core/Fragment";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import Filter from "sap/ui/model/Filter";
import FilterOperator from "sap/ui/model/FilterOperator";
import { getTopArtists, searchArtists, getArtistsByTag } from "../model/LastFmApi";
import { THEMES, applyTheme, getSavedThemeId } from "../model/themes";
import { getPlaylists } from "../model/Playlists";

/**
 * @namespace at.clouddna.music.controller
 */
export default class Artist extends Controller {

    private _activeGenreButtonId = "genreAll";
    private _currentSort = "listeners";
    private _skipNavigation = false;
    private _favorites: Set<string> = new Set();
    private readonly _STORAGE_KEY = "musicApp.favorites";
    private readonly _RECENT_KEY = "musicApp.recentArtists";
    private readonly _RECENT_MAX = 10;
    private _themePopover: any = null;
    private _activeThemeId = getSavedThemeId();

    public async onInit(): Promise<void> {
        this._loadFavorites();

        (this.getOwnerComponent() as any).getEventBus().subscribe("Artist", "resetSelection", () => {
            (this.getView()?.byId("artistList") as List).removeSelections(true);
            if (this._activeGenreButtonId === "genrePlaylists") {
                this._applyPlaylists();
            }
        });

        const raw = await getTopArtists();
        this._applyArtistsToModel(raw);
    }

    public async onSearch(oEvent: Event): Promise<void> {
        const query = (oEvent as any).getParameter("newValue") ?? "";
        this._applyFavoritesFilter(false);
        this._setActiveGenre("genreAll");
        const raw = query ? await searchArtists(query) : await getTopArtists();
        this._applyArtistsToModel(raw);
    }

    public async onGenreFilter(oEvent: Event): Promise<void> {
        const oButton = (oEvent as any).getSource() as Button;
        const genre = oButton.data("genre") as string;
        const localId = this.getView()?.getLocalId(oButton.getId()) ?? "";

        this._setActiveGenre(localId);

        const searchField = this.getView()?.byId("searchField") as any;
        searchField?.setValue("");

        if (genre === "favorites") {
            this._applyFavoritesFilter(true);
            return;
        }

        if (genre === "recent") {
            this._applyFavoritesFilter(false);
            this._applyRecentArtists();
            return;
        }

        if (genre === "playlists") {
            this._applyFavoritesFilter(false);
            this._applyPlaylists();
            return;
        }

        this._applyFavoritesFilter(false);
        const raw = genre === "all" ? await getTopArtists() : await getArtistsByTag(genre);
        this._applyArtistsToModel(raw);
    }

    public onSortChange(oEvent: Event): void {
        const key = (oEvent as any).getParameter("item")?.getKey() as string;
        this._currentSort = key;
        const model = this.getOwnerComponent()?.getModel("music") as JSONModel;
        const artists = [...(model.getProperty("/artists") as any[])];
        this._sortArtists(artists);
        model.setProperty("/artists", artists);
    }

    public onToggleFavorite(oEvent: Event): void {
        this._skipNavigation = true;

        const oButton = (oEvent as any).getSource();
        const name = oButton.getBindingContext("music")?.getProperty("name") as string;
        const willBeFavorite = oButton.getPressed() as boolean;

        if (willBeFavorite) {
            this._favorites.add(name);
        } else {
            this._favorites.delete(name);
        }
        this._saveFavorites();

        // Two-way binding already updated music>favorite on the model;
        // deselect so the item doesn't trigger navigation.
        (this.getView()?.byId("artistList") as List).removeSelections(true);
    }

    public formatListeners(value: string): string {
        const n = parseInt(value, 10);
        if (!value || isNaN(n) || n === 0) return "";
        if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M Listeners`;
        if (n >= 1_000) return `${Math.round(n / 1_000)}K Listeners`;
        return `${n.toLocaleString()} Listeners`;
    }

    private _applyArtistsToModel(raw: any[]): void {
        const artists = raw.map((a: any, i: number) => ({
            ...a,
            _originalIndex: i,
            rank: i + 1,
            icon: "sap-icon://person-placeholder",
            favorite: this._favorites.has(a.name)
        }));
        this._sortArtists(artists);
        const model = this.getOwnerComponent()?.getModel("music") as JSONModel;
        model.setProperty("/artists", artists);
        this._loadArtistImages(artists, model);
    }

    private _sortArtists(artists: any[]): void {
        if (this._currentSort === "name") {
            artists.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
        } else {
            artists.sort((a, b) => {
                const la = parseInt(a.listeners ?? "0", 10);
                const lb = parseInt(b.listeners ?? "0", 10);
                if (la === lb) return (a._originalIndex ?? 0) - (b._originalIndex ?? 0);
                return lb - la;
            });
        }
        artists.forEach((a, i) => { a.rank = i + 1; });
    }

    private _applyFavoritesFilter(active: boolean): void {
        const oList = this.getView()?.byId("artistList") as List;
        const oBinding = oList?.getBinding("items") as any;
        if (!oBinding) return;
        oBinding.filter(active ? [new Filter("favorite", FilterOperator.EQ, true)] : []);
    }

    private _setActiveGenre(localId: string): void {
        const view = this.getView();
        (view?.byId(this._activeGenreButtonId) as Button)?.removeStyleClass("genreChipActive");
        (view?.byId(localId) as Button)?.addStyleClass("genreChipActive");
        this._activeGenreButtonId = localId;
    }

    private _loadFavorites(): void {
        try {
            const stored = localStorage.getItem(this._STORAGE_KEY);
            this._favorites = new Set(stored ? JSON.parse(stored) : []);
        } catch {
            this._favorites = new Set();
        }
    }

    private _saveFavorites(): void {
        try {
            localStorage.setItem(this._STORAGE_KEY, JSON.stringify([...this._favorites]));
        } catch { /* storage unavailable */ }
    }

    private _loadArtistImages(artists: any[], model: JSONModel): void {
        artists.forEach(async (artist, index) => {
            try {
                const res = await fetch(
                    `https://www.theaudiodb.com/api/v1/json/2/search.php?s=${encodeURIComponent(artist.name)}`
                );
                const data = await res.json();
                const thumb = data.artists?.[0]?.strArtistThumb;
                if (thumb) {
                    const current = model.getProperty("/artists") as any[];
                    if (current[index]?.name === artist.name) {
                        model.setProperty(`/artists/${index}/icon`, thumb);
                    }
                }
            } catch {
                // leave icon as person-placeholder fallback
            }
        });
    }

    public onOpenStats(): void {
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteStats");
    }

    public async onOpenThemePicker(oEvent: Event): Promise<void> {
        const oSource = (oEvent as any).getSource();
        if (!this._themePopover) {
            this._themePopover = await (Fragment as any).load({
                id: this.getView()?.getId(),
                name: "at.clouddna.music.view.ThemePicker",
                controller: this
            });
            this.getView()?.addDependent(this._themePopover);
        }
        this._updateActiveSwatchClass();
        this._themePopover.openBy(oSource);
    }

    public onSelectTheme(oEvent: Event): void {
        const oButton = (oEvent as any).getSource();
        const themeId = oButton.data("themeId") as string;
        const theme = THEMES.find(t => t.id === themeId);
        if (!theme) return;
        applyTheme(theme);
        this._activeThemeId = themeId;
        this._updateActiveSwatchClass();
        this._themePopover?.close();
    }

    private _updateActiveSwatchClass(): void {
        const view = this.getView();
        THEMES.forEach(t => {
            const btn = view?.byId(`swatch${t.id.charAt(0).toUpperCase()}${t.id.slice(1)}`);
            if (!btn) return;
            if (t.id === this._activeThemeId) {
                (btn as any).addStyleClass("themeSwatchActive");
            } else {
                (btn as any).removeStyleClass("themeSwatchActive");
            }
        });
    }

    public onNavToDetail(oEvent: Event) {
        if (this._skipNavigation) {
            this._skipNavigation = false;
            return;
        }

        const oListItem = (oEvent as any).getParameters().listItem;
        const oCtx = oListItem.getBindingContext("music");

        if (oCtx?.getProperty("isPlaylist")) {
            const playlistId = oCtx.getProperty("playlistId");
            const oNextUIState = (this.getOwnerComponent() as any).getHelper().getNextUIState(1);
            (this.getOwnerComponent() as UIComponent).getRouter().navTo("RoutePlaylistDetail", {
                id: encodeURIComponent(playlistId),
                "?query": { layout: oNextUIState.layout }
            });
            return;
        }

        const sName = oCtx?.getProperty("name");
        this._saveRecentArtist(oCtx?.getObject());

        const oNextUIState = (this.getOwnerComponent() as any).getHelper().getNextUIState(1);
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtistAlbums", {
            path: encodeURIComponent(sName),
            "?query": { layout: oNextUIState.layout }
        });
    }

    private _applyPlaylists(): void {
        const playlists = getPlaylists();
        const artists = playlists.map((p, i) => ({
            name: p.name,
            listenersLabel: `${p.tracks.length} track${p.tracks.length === 1 ? "" : "s"}`,
            icon: "",
            rank: i + 1,
            favorite: false,
            isPlaylist: true,
            playlistId: p.id
        }));
        (this.getOwnerComponent()?.getModel("music") as JSONModel).setProperty("/artists", artists);
    }

    private _saveRecentArtist(artist: any): void {
        if (!artist?.name) return;
        try {
            const stored = localStorage.getItem(this._RECENT_KEY);
            let recent: any[] = stored ? JSON.parse(stored) : [];
            recent = recent.filter((a: any) => a.name !== artist.name);
            recent.unshift({ name: artist.name, listeners: artist.listeners, icon: artist.icon });
            localStorage.setItem(this._RECENT_KEY, JSON.stringify(recent.slice(0, this._RECENT_MAX)));
        } catch { /* storage unavailable */ }
    }

    private _applyRecentArtists(): void {
        try {
            const stored = localStorage.getItem(this._RECENT_KEY);
            const recent: any[] = stored ? JSON.parse(stored) : [];
            const artists = recent.map((a: any, i: number) => ({
                ...a,
                rank: i + 1,
                favorite: this._favorites.has(a.name)
            }));
            (this.getOwnerComponent()?.getModel("music") as JSONModel).setProperty("/artists", artists);
        } catch {
            (this.getOwnerComponent()?.getModel("music") as JSONModel).setProperty("/artists", []);
        }
    }
}
