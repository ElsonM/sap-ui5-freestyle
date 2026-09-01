import Controller from "sap/ui/core/mvc/Controller";
import UIComponent from "sap/ui/core/UIComponent";
import JSONModel from "sap/ui/model/json/JSONModel";
import { getStats } from "../model/ListeningStats";

/**
 * @namespace at.clouddna.music.controller
 */
export default class Stats extends Controller {

    public onInit(): void {
        (this.getOwnerComponent() as UIComponent).setModel(new JSONModel({
            totalPlays: 0,
            topArtists: [],
            genreBreakdown: [],
            streak: 0
        }), "stats");

        (this.getOwnerComponent() as UIComponent).getRouter()
            .getRoute("RouteStats")
            ?.attachPatternMatched(this._refresh, this);
    }

    private _refresh(): void {
        const stats = getStats();
        const oModel = (this.getOwnerComponent() as UIComponent).getModel("stats") as JSONModel;
        oModel.setData({
            ...stats,
            topArtists: stats.topArtists.map((a, i) => ({ ...a, rank: i + 1 }))
        });
    }

    public onClose(): void {
        const sNextLayout = (this.getOwnerComponent()?.getModel("ui") as JSONModel).getProperty("/layout");
        (this.getOwnerComponent() as UIComponent).getRouter().navTo("RouteArtist", { "?query": { layout: sNextLayout } });
    }
}
