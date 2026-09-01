sap.ui.require(
    [
        'sap/fe/test/JourneyRunner',
        'dlh/lht/placo/ppp/piecepartplanning/test/integration/FirstJourney',
		'dlh/lht/placo/ppp/piecepartplanning/test/integration/pages/PPPList',
		'dlh/lht/placo/ppp/piecepartplanning/test/integration/pages/PPPObjectPage'
    ],
    function(JourneyRunner, opaJourney, PPPList, PPPObjectPage) {
        'use strict';
        var JourneyRunner = new JourneyRunner({
            // start index.html in web folder
            launchUrl: sap.ui.require.toUrl('dlh/lht/placo/ppp/piecepartplanning') + '/index.html'
        });

       
        JourneyRunner.run(
            {
                pages: { 
					onThePPPList: PPPList,
					onThePPPObjectPage: PPPObjectPage
                }
            },
            opaJourney.run
        );
    }
);