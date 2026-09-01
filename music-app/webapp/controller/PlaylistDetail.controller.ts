import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import MessageToast from "sap/m/MessageToast";
import { getPlaylist, deletePlaylist, removeTrackFromPlaylist, Playlist } from "../model/Playlists";
import { playCustomQueue } from "../model/YoutubePlayer";

/**
 * @namespace at.clouddna.music.controller
 */
export default class PlaylistDetail extends Controller {

    private _playlistId = "";

    public onInit(): void {
        this.getView()?.setModel(new JSONModel({ id: "", name: "", tracks: [] }), "playlist");
        (this.getOwnerComponent() as UIComponent).getRouter()
            .getRoute("RoutePlaylistDetail")
            ?.attachPatternMatched(this._onPatternMatched, this);
    }

    private _onPatternMatched(oEvent: Event): void {
        const args = (oEvent as any).getParameters().arguments;
        this._playlistId = decodeURIComponent(args.id);
        this._refresh();
    }

    private _refresh(): void {
        const playlist = getPlaylist(this._playlistId);
        (this.getView()?.getModel("playlist") as JSONModel)
            .setData(playlist ?? { id: this._playlistId, name: "Playlist not found", tracks: [] });
    }

    private _getPlaylist(): Playlist {
        return (this.getView()?.getModel("playlist") as JSONModel).getData() as Playlist;
    }

    public onPlay(): void {
        const playlist = this._getPlaylist();
        if (!playlist.tracks?.length) return;
        playCustomQueue(playlist.tracks, 0);
    }

    public onShuffle(): void {
        const playlist = this._getPlaylist();
        if (!playlist.tracks?.length) return;
        const tracks = [...playlist.tracks];
        for (let i = tracks.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [tracks[i], tracks[j]] = [tracks[j], tracks[i]];
        }
        playCustomQueue(tracks, 0);
    }

    public onTrackPress(oEvent: Event): void {
        const sPath = (oEvent as any).getSource().getBindingContext("playlist")?.getPath() ?? "";
        const index = parseInt(sPath.split("/").pop() ?? "-1", 10);
        if (index < 0) return;
        playCustomQueue(this._getPlaylist().tracks, index);
    }

    public onRemoveTrack(oEvent: Event): void {
        const sPath = (oEvent as any).getSource().getBindingContext("playlist")?.getPath() ?? "";
        const index = parseInt(sPath.split("/").pop() ?? "-1", 10);
        if (index < 0) return;
        removeTrackFromPlaylist(this._playlistId, index);
        this._refresh();
    }

    public onDeletePlaylist(): void {
        deletePlaylist(this._playlistId);
        MessageToast.show("Playlist deleted");
        this.handleClose();
    }

    public handleFullScreen() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/midColumn/fullScreen");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RoutePlaylistDetail", {
            id: this._playlistId,
            "?query": { layout: sNextLayout }
        });
    }

    public handleExitFullScreen() {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/actionButtonsInfo/midColumn/exitFullScreen");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RoutePlaylistDetail", {
            id: this._playlistId,
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
