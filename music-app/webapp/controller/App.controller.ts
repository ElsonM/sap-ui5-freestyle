import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import Fragment from "sap/ui/core/Fragment";
import { togglePlayPause, skipToNext, skipToPrev, seekTo, setVolume, jumpToTrack, removeFromQueue, moveQueueItem } from "../model/YoutubePlayer";

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
    }

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
        const newVal = (oEvent as any).getSource().getPressed() as boolean;
        try { localStorage.setItem("musicApp.shuffleOn", String(newVal)); } catch { /* storage unavailable */ }
    }

    public onExit(): void {
        document.removeEventListener("keydown", this._onKeyDown);
    }

    private _queueDrawer: any = null;

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
}
