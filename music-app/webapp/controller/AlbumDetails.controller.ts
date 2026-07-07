import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import { getAlbumInfo, formatDuration, stripHtml, extractYear, toArray } from "../model/LastFmApi";
import { playQueue } from "../model/YoutubePlayer";

/**
 * @namespace at.clouddna.music.controller
 */
export default class AlbumDetails extends Controller {

    private sArtistPath: string;
    private sAlbumPath: string;

    public onInit(): void {
        (this.getOwnerComponent() as UIComponent).getRouter()
            .getRoute("RouteAlbumDetails")
            ?.attachPatternMatched(this.onPatternMatched, this);
    }

    private async onPatternMatched(oEvent: Event): Promise<void> {
        const args = (oEvent as any).getParameters().arguments;
        const sArtistName = decodeURIComponent(args.path);
        const sAlbumName = decodeURIComponent(args.albumPath);
        this.sArtistPath = args.path;
        this.sAlbumPath = args.albumPath;

        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        oModel.setProperty("/currentAlbum", null);

        const album = await getAlbumInfo(sArtistName, sAlbumName);
        if (!album) return;

        const tags = toArray(album.tags?.tag);
        const tracks = toArray(album.tracks?.track).map((t: any, i: number) => ({
            rank: t["@attr"]?.rank ?? i + 1,
            name: t.name,
            duration: formatDuration(Number(t.duration))
        }));

        oModel.setProperty("/currentAlbum", {
            name: album.name,
            artistName: album.artist,
            year: extractYear(album.wiki?.published ?? ""),
            genre: tags[0]?.name ?? "",
            songCount: tracks.length,
            description: stripHtml(album.wiki?.summary ?? ""),
            image: album.image?.find((img: any) => img.size === "extralarge")?.["#text"] ?? "",
            tracks
        });
    }

    public onPlay(): void {
        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        const tracks = oModel.getProperty("/currentAlbum/tracks");
        const artistName = oModel.getProperty("/currentAlbum/artistName");
        const albumName = oModel.getProperty("/currentAlbum/name");
        const albumImage = oModel.getProperty("/currentAlbum/image");
        playQueue(tracks, artistName, albumName, albumImage, 0);
    }

    public onShuffle(): void {
        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        const tracks = [...(oModel.getProperty("/currentAlbum/tracks") as any[])];
        for (let i = tracks.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [tracks[i], tracks[j]] = [tracks[j], tracks[i]];
        }
        const artistName = oModel.getProperty("/currentAlbum/artistName");
        const albumName = oModel.getProperty("/currentAlbum/name");
        const albumImage = oModel.getProperty("/currentAlbum/image");
        playQueue(tracks, artistName, albumName, albumImage, 0);
    }

    public onTrackPress(oEvent: Event): void {
        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        const tracks = oModel.getProperty("/currentAlbum/tracks") as any[];
        const artistName = oModel.getProperty("/currentAlbum/artistName");
        const albumName = oModel.getProperty("/currentAlbum/name");
        const albumImage = oModel.getProperty("/currentAlbum/image");
        const rank = (oEvent as any).getSource().getBindingContext("music").getProperty("rank");
        const index = tracks.findIndex((t: any) => t.rank === rank);
        playQueue(tracks, artistName, albumName, albumImage, index >= 0 ? index : 0);
    }

    public handleFullScreen() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/endColumn/fullScreen");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteAlbumDetails", {
            path: this.sArtistPath,
            albumPath: this.sAlbumPath,
            "?query": { layout: sNextLayout }
        });
    }

    public handleExitFullScreen() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/endColumn/exitFullScreen");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteAlbumDetails", {
            path: this.sArtistPath,
            albumPath: this.sAlbumPath,
            "?query": { layout: sNextLayout }
        });
    }

    public handleClose() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/endColumn/closeColumn");
        (this.getOwnerComponent() as any).getEventBus().publish("ArtistAlbums", "resetSelection");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtistAlbums", {
            path: this.sArtistPath,
            "?query": { layout: sNextLayout }
        });
    }
}
