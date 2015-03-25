'use strict';

/**
 * @ngdoc function
 * @name frontendYoApp.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of the frontendYoApp
 */
angular.module('frontendYoApp')
  .controller('MainCtrl', function ($scope) {

    $scope.lost_treasure = {};
    $scope.lost_treasure.service = "ABS-CBN Customer Care Text Hotline";
    $scope.lost_treasure.tester = "Lea Samoy";
    $scope.lost_treasure.mobtel_number = "9356102709";
    $scope.lost_treasure.network = "TM";

    $scope.lost_treasure.mock_entries = [
        {
            "ref_no": 1,
            "test_date": "2/18/2015",
            "scenario":  "Subscriber sends query or message for the 1st or 2nd time within the day",
            "keyword": "How do I join the MMK text promo?",
            "a_number":"9356102709",
            "b_number":"23661",
            "time_sent":"2:19 PM",
            "time_received":"2:20 PM",
            "beginning_balance":"10.00",
            "ending_balance":"10.00",
            "amount_charged":"0.00",
            "expected_result":"ABS-CBN TV Plus: Hi Kapamilya! Salamat po sa interest ninyo sa ABS-CBN TV plus. Ito po ay available na sa SM Appliance, SolidService Center, 2GO, Silicon Valley, Villman, Puregold Ambassador, Asianic, Complink, Accent Micro, PC Hub, PC Express, PC Corner, PC Worx sa halagang P2,500.00. Salamat po. This message is free of charge.",
            "actual_result":"ABS-CBN TV Plus: Hi Kapamilya! Salamat po sa interest ninyo sa ABS-CBN TV plus. Ito po ay available na sa SM Appliance, SolidService Center, 2GO, Silicon Valley, Villman, Puregold Ambassador, Asianic, Complink, Accent Micro, PC Hub, PC Express, PC Corner, PC Worx sa halagang P2,500.00. Salamat po. This message is free of charge.",
            "pass_fail":"P",
            "remarks":"OK"
        }
    ];
    
    $scope.lost_treasure.entries = $scope.lost_treasure.mock_entries;
    
  });
