sap.ui.define(['sap/fe/test/ObjectPage'], function(ObjectPage) {
    'use strict';

    var CustomPageDefinitions = {
        actions: {},
        assertions: {}
    };

    return new ObjectPage(
        {
            appId: 'dlh.lht.placo.ppp.piecepartplanning',
            componentId: 'PPPObjectPage',
            contextPath: '/PPP'
        },
        CustomPageDefinitions
    );
});