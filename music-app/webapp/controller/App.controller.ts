import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import Fragment from "sap/ui/core/Fragment";
import { togglePlayPause, skipToNext, skipToPrev, seekTo, setVolume, jumpToTrack, removeFromQueue, moveQueueItem } from "../model/YoutubePlayer";
import { getLyrics } from "../model/LyricsApi";
import { writeFlag } from "../model/storage";

/**
 * @namespace at.clouddna.music.controller
 */
export default class App extends Controller {

    private _onKeyDown = (e: KeyboardEvent): void => {
        const tag = (document.activeElement?.tagName ?? "").toLowerCase();
        if (tag === "input" || tag === "textarea") return;

        const playerVisible = ((this.getOwnerComponent() as UIComponent).getModel("player") as JSONModel).getProperty("/visible") as boolean;
        if (!playerVisible) return;

        if (e.code === "Space") {
            e.preventDefault();
            togglePlayPause();
        } else if (e.code === "ArrowLeft") {
            e.preventDefault();
            skipToPrev();
        } else if (e.code === "ArrowRight") {
            e.preventDefault();
            skipToNext();
        }
    };

    /*eslint-disable @typescript-eslint/no-empty-function*/
    public onInit(): void {
        document.addEventListener("keydown", this._onKeyDown);
        let oOwnerComponent = (this.getOwnerComponent() as UIComponent);
        oOwnerComponent.getRouter().attachRouteMatched(this.onRouteMatched, this);
        oOwnerComponent.setModel(new JSONModel({ layout: "OneColumn" }), "ui");
        (oOwnerComponent.getModel("player") as JSONModel).attachPropertyChange(this._onPlayerPropertyChange, this);
    }

    private _onPlayerPropertyChange = (oEvent: Event): void => {
        if (!this._lyricsOpen) return;
        const sPath = (oEvent as any).getParameter("path");
        if (sPath === "/currentTrack") {
            this._refreshLyrics();
        } else if (sPath === "/progress") {
            this._syncLyricsScroll();
        }
    };

    private onRouteMatched(oEvent: Event) {
        let sLayout = (oEvent as any).getParameters().arguments["?query"]?.layout;

        if (!sLayout) {
            let oNextUIState = (this.getOwnerComponent() as any).getHelper().getNextUIState(0);
            sLayout = oNextUIState.layout;
        }

        if (sLayout) {
            ((this.getOwnerComponent() as UIComponent).getModel("ui") as JSONModel).setProperty("/layout", sLayout);
        }

        let oActionButtonsInfo = (this.getOwnerComponent() as any).getHelper().getCurrentUIState().actionButtonsInfo;
        ((this.getOwnerComponent() as UIComponent).getModel("ui") as JSONModel).setProperty("/actionButtonsInfo", oActionButtonsInfo);
    }

    public onTogglePlay(): void {
        togglePlayPause();
    }

    public onNext(): void {
        skipToNext();
    }

    public onPrev(): void {
        skipToPrev();
    }

    public onSeek(oEvent: Event): void {
        seekTo((oEvent as any).getParameter("value"));
    }

    public onVolumeChange(oEvent: Event): void {
        setVolume((oEvent as any).getParameter("value"));
    }

    public onToggleShuffle(oEvent: Event): void {
        writeFlag("musicApp.shuffleOn", (oEvent as any).getSource().getPressed() as boolean);
    }

    public onToggleRadio(oEvent: Event): void {
        writeFlag("musicApp.radioOn", (oEvent as any).getSource().getPressed() as boolean);
    }

    public onExit(): void {
        document.removeEventListener("keydown", this._onKeyDown);
        ((this.getOwnerComponent() as UIComponent).getModel("player") as JSONModel).detachPropertyChange(this._onPlayerPropertyChange, this);
    }

    private _queueDrawer: any = null;
    private _lyricsPanel: any = null;
    private _lyricsOpen = false;
    private _lyricsTrackKey = "";
    private _lastActiveLyricsIndex = -1;

    public async onOpenQueue(): Promise<void> {
        if (!this._queueDrawer) {
            this._queueDrawer = await (Fragment as any).load({
                id: this.getView()?.getId(),
                name: "at.clouddna.music.view.QueueDrawer",
                controller: this
            });
            this.getView()?.addDependent(this._queueDrawer);
        }
        this._queueDrawer.open();
    }

    public onCloseQueue(): void {
        this._queueDrawer?.close();
    }

    public onQueueTrackPress(oEvent: Event): void {
        const sPath = (oEvent as any).getSource().getBindingContext("player")?.getPath() ?? "";
        const index = parseInt(sPath.split("/").pop() ?? "-1", 10);
        if (index >= 0) jumpToTrack(index);
    }

    public onRemoveFromQueue(oEvent: Event): void {
        const sPath = (oEvent as any).getSource().getBindingContext("player")?.getPath() ?? "";
        const index = parseInt(sPath.split("/").pop() ?? "-1", 10);
        if (index >= 0) removeFromQueue(index);
    }

    public onQueueDrop(oEvent: Event): void {
        const oDragged = (oEvent as any).getParameter("draggedControl");
        const oDropped = (oEvent as any).getParameter("droppedControl");
        const sDropPosition = (oEvent as any).getParameter("dropPosition") as string;

        const fromIndex = parseInt((oDragged.getBindingContext("player").getPath() as string).split("/").pop() ?? "-1", 10);
        let toIndex = parseInt((oDropped.getBindingContext("player").getPath() as string).split("/").pop() ?? "-1", 10);
        if (fromIndex < 0 || toIndex < 0 || fromIndex === toIndex) return;

        if (sDropPosition === "After") toIndex++;
        if (fromIndex < toIndex) toIndex--;

        moveQueueItem(fromIndex, toIndex);
    }

    public onToggleRepeat(): void {
        const oModel = (this.getOwnerComponent() as UIComponent).getModel("player") as JSONModel;
        const cur = oModel.getProperty("/repeatMode") as string;
        const next = cur === "off" ? "all" : cur === "all" ? "one" : "off";
        oModel.setProperty("/repeatMode", next);
        try { localStorage.setItem("musicApp.repeatMode", next); } catch { /* storage unavailable */ }
    }

    public async onOpenLyrics(): Promise<void> {
        if (!this._lyricsPanel) {
            this._lyricsPanel = await (Fragment as any).load({
                id: this.getView()?.getId(),
                name: "at.clouddna.music.view.LyricsPanel",
                controller: this
            });
            this.getView()?.addDependent(this._lyricsPanel);
        }
        this._lyricsOpen = true;
        this._lyricsPanel.open();
        this._refreshLyrics();
    }

    public onCloseLyrics(): void {
        this._lyricsOpen = false;
        this._lyricsPanel?.close();
    }

    private async _refreshLyrics(): Promise<void> {
        const oModel = (this.getOwnerComponent() as UIComponent).getModel("player") as JSONModel;
        const track = oModel.getProperty("/currentTrack") as { name: string; artistName: string; albumName?: string } | null;

        this._lastActiveLyricsIndex = -1;

        if (!track?.name || !track?.artistName) {
            this._lyricsTrackKey = "";
            oModel.setProperty("/lyrics", { lines: [], plainText: "", loading: false });
            return;
        }

        const key = `${track.artistName}|${track.name}`;
        if (key === this._lyricsTrackKey) return;
        this._lyricsTrackKey = key;

        oModel.setProperty("/lyrics", { lines: [], plainText: "", loading: true });
        const result = await getLyrics(track.artistName, track.name, track.albumName);

        if (this._lyricsTrackKey !== key) return;

        if (result.synced?.length) {
            const lines = result.synced.map((line, i) => ({
                time: line.time,
                endTime: result.synced![i + 1]?.time ?? Infinity,
                text: line.text,
                active: false
            }));
            oModel.setProperty("/lyrics", { lines, plainText: "", loading: false });
        } else {
            oModel.setProperty("/lyrics", { lines: [], plainText: result.plain ?? "", loading: false });
        }
    }

    private _syncLyricsScroll(): void {
        const oModel = (this.getOwnerComponent() as UIComponent).getModel("player") as JSONModel;
        const lines = oModel.getProperty("/lyrics/lines") as Array<{ time: number; endTime: number }>;
        if (!lines?.length) return;

        const progress = oModel.getProperty("/progress") as number;
        let index = lines.findIndex(l => progress >= l.time && progress < l.endTime);
        if (index === -1 && lines.length && progress >= lines[lines.length - 1].time) {
            index = lines.length - 1;
        }
        if (index === -1 || index === this._lastActiveLyricsIndex) return;

        if (this._lastActiveLyricsIndex >= 0) {
            oModel.setProperty(`/lyrics/lines/${this._lastActiveLyricsIndex}/active`, false);
        }
        oModel.setProperty(`/lyrics/lines/${index}/active`, true);
        this._lastActiveLyricsIndex = index;

        const list = (Fragment as any).byId(this.getView()?.getId(), "lyricsLinesList");
        const item = list?.getItems?.()[index];
        (item?.getDomRef() as HTMLElement | undefined)?.scrollIntoView({ block: "center", behavior: "smooth" });
    }
}
