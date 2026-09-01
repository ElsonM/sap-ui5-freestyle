sap.ui.define(['sap/fe/test/ListReport'], function(ListReport) {
    'use strict';

    var CustomPageDefinitions = {
        actions: {},
        assertions: {}
    };

    return new ListReport(
        {
            appId: 'dlh.lht.placo.ppp.piecepartplanning',
            componentId: 'PPPList',
            contextPath: '/PPP'
        },
        CustomPageDefinitions
    );
});