'use strict';

/**
 * @ngdoc function
 * @name frontendYoApp.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of the frontendYoApp
 */
angular.module('frontendYoApp')
  .controller('MainCtrl', function ($scope, $http) {
      
    /** TODO: Configure this somewhere **/
    var endpoint = 'http://dev.aws.galoretv.com:3007';
      
    var statuses = {
        'local_queue': 'Local Queue',
        'remote_queue': 'Remote Queue'
    };

    $scope.lost_treasure = {};
    $scope.lost_treasure.service = 'ABS-CBN Customer Care Text Hotline';
    $scope.lost_treasure.tester = 'Lea Samoy';
    $scope.lost_treasure.mobtel_number = '9356102709';
    $scope.lost_treasure.network = 'TM';

    $scope.lost_treasure.mock_entries = [
        {
            'ref_no': 1,
            'test_date': '2/18/2015',
            'scenario':  'Subscriber sends query or message for the 1st or 2nd time within the day',
            'keyword': 'How do I join the MMK text promo?',
            'a_number':'9356102709',
            'b_number':'23661',
            'time_sent':'2:19 PM',
            'time_received':'2:20 PM',
            'beginning_balance':'10.00',
            'ending_balance':'10.00',
            'amount_charged':'0.00',
            'expected_result':'ABS-CBN TV Plus: Hi Kapamilya! Salamat po sa interest ninyo sa ABS-CBN TV plus. Ito po ay available na sa SM Appliance, SolidService Center, 2GO, Silicon Valley, Villman, Puregold Ambassador, Asianic, Complink, Accent Micro, PC Hub, PC Express, PC Corner, PC Worx sa halagang P2,500.00. Salamat po. This message is free of charge.',
            'actual_result':'ABS-CBN TV Plus: Hi Kapamilya! Salamat po sa interest ninyo sa ABS-CBN TV plus. Ito po ay available na sa SM Appliance, SolidService Center, 2GO, Silicon Valley, Villman, Puregold Ambassador, Asianic, Complink, Accent Micro, PC Hub, PC Express, PC Corner, PC Worx sa halagang P2,500.00. Salamat po. This message is free of charge.',
            'pass_fail':'P',
            'remarks':'OK',
            'meta': {
                'loading': false
            }
        }
    ];
    
    $scope.lost_treasure.entries = $scope.lost_treasure.mock_entries;
    $scope.lost_treasure.running = false;
    
    $scope.lost_treasure.tmp = {
        batch: new Date().getTime(),
        sequence_no: 1
    };
    
    $scope.lost_treasure.methods = {
        
        /** Test method **/
        honk:function() {   
            
            /** Randomize message **/
            
            var scenario = {
                'batch': $scope.lost_treasure.tmp.batch,
                'id': new Date().getTime(),
                'sequence_no': $scope.lost_treasure.tmp.sequence_no++,
                'keyword': 'BAL',
                'a_number': '+639173292739',
                'b_number': '222',
                'expected_result':'Blurbblurb'
            };
            
            $http.post(endpoint + '/scenarios', scenario).
             success(function(data, status, headers, config) {
                // this callback will be called asynchronously
                // when the response is available
              }).
              error(function(data, status, headers, config) {
                // called asynchronously if an error occurs
                // or server returns response with an error status.
              });            
            
        },
        
        add_entry: function() {
            var last_entry = $scope.lost_treasure.entries[$scope.lost_treasure.entries.length - 1];
            var ref_no;
            if (last_entry) {
                ref_no = last_entry.ref_no + 1;
            } else {
                ref_no = 1;
            }
            $scope.lost_treasure.entries.push({
                'ref_no': ref_no, 
                'meta': {
                    'loading':false
                }
            });
        },
        
        remove_entry: function(index) {
            if (confirm('Do you really want to delete this row?')) {
                $scope.lost_treasure.entries.splice(index,1);
            }
        },
        
        run: function() {
            $scope.lost_treasure.running = true;
            for (var i = 0; i < $scope.lost_treasure.entries.length; i++) {
                $scope.lost_treasure.entries[i].meta.loading = true;
                $scope.lost_treasure.entries[i].status = statuses.local_queue;
            }
        
        }
    };
    
  });
