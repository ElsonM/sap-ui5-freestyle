import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import Fragment from "sap/ui/core/Fragment";
import MessageToast from "sap/m/MessageToast";
import { getAlbumInfo, formatDuration, stripHtml, extractYear, toArray } from "../model/LastFmApi";
import { playQueue } from "../model/YoutubePlayer";
import { getPlaylists, createPlaylist, addTrackToPlaylist, PlaylistTrack } from "../model/Playlists";

/**
 * @namespace at.clouddna.music.controller
 */
export default class AlbumDetails extends Controller {

    private sArtistPath: string;
    private sAlbumPath: string;
    private _addToPlaylistPopover: any = null;
    private _pendingTrack: Omit<PlaylistTrack, "rank"> | null = null;

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
        const genre = oModel.getProperty("/currentAlbum/genre");
        playQueue(tracks, artistName, albumName, albumImage, 0, genre);
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
        const genre = oModel.getProperty("/currentAlbum/genre");
        playQueue(tracks, artistName, albumName, albumImage, 0, genre);
    }

    public onTrackPress(oEvent: Event): void {
        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;
        const tracks = oModel.getProperty("/currentAlbum/tracks") as any[];
        const artistName = oModel.getProperty("/currentAlbum/artistName");
        const albumName = oModel.getProperty("/currentAlbum/name");
        const albumImage = oModel.getProperty("/currentAlbum/image");
        const genre = oModel.getProperty("/currentAlbum/genre");
        const rank = (oEvent as any).getSource().getBindingContext("music").getProperty("rank");
        const index = tracks.findIndex((t: any) => t.rank === rank);
        playQueue(tracks, artistName, albumName, albumImage, index >= 0 ? index : 0, genre);
    }

    public async onAddToPlaylist(oEvent: Event): Promise<void> {
        const oSource = (oEvent as any).getSource();
        const track = oSource.getBindingContext("music")?.getObject();
        const oModel = this.getOwnerComponent()?.getModel("music") as JSONModel;

        this._pendingTrack = {
            name: track.name,
            duration: track.duration,
            artistName: oModel.getProperty("/currentAlbum/artistName"),
            albumName: oModel.getProperty("/currentAlbum/name"),
            albumImage: oModel.getProperty("/currentAlbum/image")
        };

        if (!this._addToPlaylistPopover) {
            this._addToPlaylistPopover = await (Fragment as any).load({
                id: this.getView()?.getId(),
                name: "at.clouddna.music.view.AddToPlaylist",
                controller: this
            });
            this.getView()?.addDependent(this._addToPlaylistPopover);
        }

        (this.getOwnerComponent()?.getModel("playlists") as JSONModel).setProperty("/list", getPlaylists());
        this._addToPlaylistPopover.openBy(oSource);
    }

    public onSelectPlaylistForAdd(oEvent: Event): void {
        if (!this._pendingTrack) return;
        const id = (oEvent as any).getSource().getBindingContext("playlists")?.getProperty("id");
        const added = addTrackToPlaylist(id, this._pendingTrack);
        this._addToPlaylistPopover?.close();
        MessageToast.show(added ? "Added to playlist" : "Already in that playlist");
    }

    public onCreatePlaylistAndAdd(): void {
        const oModel = this.getOwnerComponent()?.getModel("playlists") as JSONModel;
        const name = ((oModel.getProperty("/newPlaylistName") as string) || "").trim();
        if (!name || !this._pendingTrack) return;

        const playlist = createPlaylist(name);
        addTrackToPlaylist(playlist.id, this._pendingTrack);
        oModel.setProperty("/newPlaylistName", "");
        this._addToPlaylistPopover?.close();
        MessageToast.show(`Created "${name}" and added track`);
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
