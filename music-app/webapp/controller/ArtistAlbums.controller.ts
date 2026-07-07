import List from "sap/m/List";
import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import { getTopAlbums, getArtistInfo, getSimilarArtists, getAlbumInfo, stripHtml, stripHtmlPreserveParagraphs, extractYear, toArray } from "../model/LastFmApi";

/**
 * @namespace at.clouddna.music.controller
 */
export default class ArtistAlbums extends Controller {

    private sCurrentArtistPath: string;
    private sCachedArtistName: string = "";
    private _rawAlbums: any[] = [];
    private _albumSortBy: string = "popularity";

    public onInit(): void {
        const oRouter = (this.getOwnerComponent() as UIComponent).getRouter();
        oRouter.getRoute("RouteArtistAlbums")?.attachPatternMatched(this.onPatternMatched, this);
        oRouter.getRoute("RouteAlbumDetails")?.attachPatternMatched(this.onPatternMatched, this);

        (this.getOwnerComponent() as any).getEventBus().subscribe("ArtistAlbums", "resetSelection", () => {
            (this.getView()?.byId("albumList") as List).removeSelections(true);
        });
    }

    private async onPatternMatched(oEvent: Event): Promise<void> {
        const args = (oEvent as any).getParameters().arguments;
        const sArtistName = decodeURIComponent(args.path);
        this.sCurrentArtistPath = args.path;

        if (sArtistName === this.sCachedArtistName) return;
        this.sCachedArtistName = sArtistName;

        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        oModel.setProperty("/currentArtist", sArtistName);
        oModel.setProperty("/albums", []);
        oModel.setProperty("/loadingAlbums", true);

        // Populate header from the already-loaded artists list
        const artists = oModel.getProperty("/artists") as any[];
        const matched = artists?.find((a: any) => a.name === sArtistName);
        const icon = matched?.icon ?? "sap-icon://person-placeholder";
        oModel.setProperty("/currentArtistIcon", icon);
        oModel.setProperty("/currentArtistListeners", matched ? this._formatListeners(matched.listeners) : "");

        // If artist image hasn't loaded yet, fetch it directly
        if (!matched?.icon || matched.icon === "sap-icon://person-placeholder") {
            fetch(`https://www.theaudiodb.com/api/v1/json/2/search.php?s=${encodeURIComponent(sArtistName)}`)
                .then(r => r.json())
                .then(data => {
                    const thumb = data.artists?.[0]?.strArtistThumb;
                    if (thumb) oModel.setProperty("/currentArtistIcon", thumb);
                })
                .catch(() => {});
        }

        const [raw, artistInfo, similar] = await Promise.all([
            getTopAlbums(sArtistName),
            getArtistInfo(sArtistName),
            getSimilarArtists(sArtistName)
        ]);

        const albums = raw.map((a: any) => ({
            ...a,
            imageUrl: a.image?.find((img: any) => img.size === "extralarge")?.["#text"]
                   ?? a.image?.find((img: any) => img.size === "large")?.["#text"]
                   ?? "",
            year: ""
        }));

        const tags = toArray(artistInfo?.tags?.tag)
            .slice(0, 4)
            .map((t: any) => t.name)
            .join("  ·  ");

        const rawBio = artistInfo?.bio?.summary ?? "";
        const bio = rawBio ? this._truncate(stripHtml(rawBio), 600) : "";

        const rawFullBio = artistInfo?.bio?.content ?? artistInfo?.bio?.summary ?? "";
        const fullBio = rawFullBio ? stripHtmlPreserveParagraphs(rawFullBio) : "";

        const similarArtists = similar.map((a: any) => ({
            name: a.name,
            icon: "sap-icon://person-placeholder"
        }));

        this._rawAlbums = albums;
        this._albumSortBy = "popularity";

        oModel.setProperty("/albums", this._sortAlbums(albums, this._albumSortBy));
        oModel.setProperty("/albumSortBy", this._albumSortBy);
        oModel.setProperty("/currentArtistTags", tags);
        oModel.setProperty("/currentArtistBio", bio);
        oModel.setProperty("/currentArtistFullBio", fullBio);
        oModel.setProperty("/similarArtists", similarArtists);
        oModel.setProperty("/loadingAlbums", false);

        this._loadSimilarArtistImages(similarArtists, oModel);
        this._loadAlbumYears(sArtistName, albums, oModel);
    }

    private _sortAlbums(albums: any[], sortBy: string): any[] {
        const arr = [...albums];
        if (sortBy === "year") {
            arr.sort((a, b) => (parseInt(b.year, 10) || 0) - (parseInt(a.year, 10) || 0));
        } else if (sortBy === "yearAsc") {
            arr.sort((a, b) => (parseInt(a.year, 10) || 9999) - (parseInt(b.year, 10) || 9999));
        } else if (sortBy === "playcount") {
            arr.sort((a, b) => (parseInt(b.playcount, 10) || 0) - (parseInt(a.playcount, 10) || 0));
        }
        return arr;
    }

    private _loadAlbumYears(artistName: string, albums: any[], oModel: JSONModel): void {
        Promise.all(albums.map(async (album, index) => {
            try {
                const info = await getAlbumInfo(artistName, album.name);
                const year = extractYear(info?.wiki?.published ?? "");
                if (year) albums[index] = { ...albums[index], year };
            } catch { /* leave year empty */ }
        })).then(() => {
            if (this._rawAlbums !== albums) return;
            oModel.setProperty("/albums", this._sortAlbums(albums, this._albumSortBy));
        });
    }

    public onAlbumSortChange(oEvent: Event): void {
        const sortBy = (oEvent as any).getParameter("selectedItem")?.getKey() as string ?? "popularity";
        this._albumSortBy = sortBy;

        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        oModel.setProperty("/albumSortBy", sortBy);
        oModel.setProperty("/albums", this._sortAlbums(this._rawAlbums, sortBy));
    }

    private _loadSimilarArtistImages(artists: Array<{ name: string }>, oModel: JSONModel): void {
        artists.forEach((artist, index) => {
            fetch(`https://www.theaudiodb.com/api/v1/json/2/search.php?s=${encodeURIComponent(artist.name)}`)
                .then(r => r.json())
                .then(data => {
                    const thumb = data.artists?.[0]?.strArtistThumb;
                    if (!thumb) return;
                    const current = oModel.getProperty("/similarArtists") as Array<{ name: string }>;
                    if (current[index]?.name === artist.name) {
                        oModel.setProperty(`/similarArtists/${index}/icon`, thumb);
                    }
                })
                .catch(() => { /* keep fallback icon */ });
        });
    }

    public formatPlaycount(value: string | number): string {
        const n = typeof value === "number" ? value : parseInt(value as string, 10);
        if (!value || isNaN(n) || n === 0) return "";
        if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M plays`;
        if (n >= 1_000) return `${Math.round(n / 1_000)}K plays`;
        return `${n.toLocaleString()} plays`;
    }

    private _truncate(text: string, max: number): string {
        return text.length <= max ? text : text.slice(0, max).trimEnd() + "…";
    }

    private _formatListeners(value: string): string {
        const n = parseInt(value, 10);
        if (!value || isNaN(n) || n === 0) return "";
        if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M Listeners`;
        if (n >= 1_000) return `${Math.round(n / 1_000)}K Listeners`;
        return `${n.toLocaleString()} Listeners`;
    }

    public onNavToAlbumDetail(oEvent: Event) {
        const oListItem = (oEvent as any).getParameters().listItem;
        const sAlbumName = oListItem.getBindingContext("music")?.getProperty("name");
        const oNextUIState = (this.getOwnerComponent() as any).getHelper().getNextUIState(2);

        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteAlbumDetails", {
            path: this.sCurrentArtistPath,
            albumPath: encodeURIComponent(sAlbumName),
            "?query": { layout: oNextUIState.layout }
        });
    }

    public onSimilarArtistPress(oEvent: Event): void {
        const oCtx = (oEvent as any).getSource().getBindingContext("music");
        const sName = oCtx?.getProperty("name");
        if (!sName) return;

        const sLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/layout");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtistAlbums", {
            path: encodeURIComponent(sName),
            "?query": { layout: sLayout }
        });
    }

    public handleFullScreen() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/midColumn/fullScreen");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtistAlbums", {
            path: this.sCurrentArtistPath,
            "?query": { layout: sNextLayout }
        });
    }

    public handleExitFullScreen() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/midColumn/exitFullScreen");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtistAlbums", {
            path: this.sCurrentArtistPath,
            "?query": { layout: sNextLayout }
        });
    }

    public handleClose() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/midColumn/closeColumn");
        (this.getOwnerComponent() as any).getEventBus().publish("Artist", "resetSelection");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtist", {
            "?query": { layout: sNextLayout }
        });
    }
}
