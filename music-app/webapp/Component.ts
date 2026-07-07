import BaseComponent from "sap/ui/core/UIComponent";
import { createDeviceModel } from "./model/models";
import { LayoutType } from "sap/f/library";
import FlexibleColumnLayoutSemanticHelper from "sap/f/FlexibleColumnLayoutSemanticHelper";
import FlexibleColumnLayout from "sap/f/FlexibleColumnLayout";
import JSONModel from "sap/ui/model/json/JSONModel";
import { initYoutubePlayer } from "./model/YoutubePlayer";
import { loadSavedTheme } from "./model/themes";

/**
 * @namespace at.clouddna.music
 */
export default class Component extends BaseComponent {

    public static metadata = {
        manifest: "json"
    };

    public init(): void {
        super.init();
        loadSavedTheme();
        this.getRouter().initialize();
        this.setModel(createDeviceModel(), "device");
        this.setModel(new JSONModel({
            artists: [],
            currentArtist: "",
            albums: [],
            currentAlbum: null
        }), "music");
        const savedVol = parseInt(localStorage.getItem("musicApp.volume") ?? "80", 10);
        const savedRepeat = (localStorage.getItem("musicApp.repeatMode") ?? "off") as "off" | "all" | "one";
        const savedShuffle = localStorage.getItem("musicApp.shuffleOn") === "true";
        const playerModel = new JSONModel({
            isPlaying: false,
            isLoading: false,
            currentTrack: null,
            progress: 0,
            duration: 0,
            progressPercent: 0,
            progressTime: "0:00",
            durationTime: "0:00",
            queue: [],
            queueIndex: -1,
            visible: false,
            volume: savedVol,
            repeatMode: savedRepeat,
            shuffleOn: savedShuffle
        });
        this.setModel(playerModel, "player");
        initYoutubePlayer(playerModel);
    }

    public getHelper() {
        var oFCL = (this.getRootControl() as any).byId("fcl") as FlexibleColumnLayout,
            oParams = new URLSearchParams(window.location.search),
            oSettings = {
                defaultTwoColumnLayoutType: LayoutType.TwoColumnsMidExpanded,
                defaultThreeColumnLayoutType: LayoutType.ThreeColumnsMidExpanded,
                maxColumnsCount: oParams.get("max")
            };

        return FlexibleColumnLayoutSemanticHelper.getInstanceFor(oFCL, oSettings);
    }
}
