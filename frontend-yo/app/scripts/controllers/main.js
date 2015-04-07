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
        'remote_queue': 'Remote Queue',
        'done': 'Done'
    };

    $scope.lost_treasure = {};
    $scope.lost_treasure.service = 'Piso Club Service';
    $scope.lost_treasure.tester = 'KATE	';
    $scope.lost_treasure.mobtel_number = '09273299820';
    $scope.lost_treasure.network = 'GHP';

    /** Counters keep track of the sequence and batch of the scenarios **/
    $scope.lost_treasure.counters = {
        batch: new Date().getTime(),
        sequence_no: 1
    };


    $scope.lost_treasure.running = false;
    

    
    $scope.lost_treasure.methods = {
        
        /** Test method **/
        honk:function() {   
            
            /** Randomize message **/
            
            var scenario = {
                'batch': $scope.lost_treasure.counters.batch,
                'id': new Date().getTime(),
                'sequence_no': $scope.lost_treasure.counters.sequence_no++,
                'keyword': 'BAL',
                'a_number': '+639173292739',
                'b_number': '222',
                'expected_result':'Blurbblurb'
            };
            
            $http.post(endpoint + '/scenarios', angular.toJson(scenario)).
             success(function() {
                // this callback will be called asynchronously
                // when the response is available
              }).
              error(function() {
                // called asynchronously if an error occurs
                // or server returns response with an error status.
              });            
            
        },
        
        beep: function(text) {
          //var alert;
          alert(text);   // jshint ignore:line
        },
        
        generate_id: function() {
            return new Date().getTime();
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
            //var confirm;
            if (confirm('Do you really want to delete this row?')) { // jshint ignore:line
                $scope.lost_treasure.entries.splice(index,1);
            }
        },
        
        push: function(scenario) {
            $http.post(endpoint + '/scenarios', angular.toJson(scenario)).
              error(function() {
                // TODO: invoke again on failure
              });              
        },
        
        run: function() {
            $scope.lost_treasure.running = true;
            
            //Set loading icons a-circling to give the user sense of movement and progress
            for (var i = 0; i < $scope.lost_treasure.entries.length; i++) {
                $scope.lost_treasure.entries[i].meta.loading = true;
                $scope.lost_treasure.entries[i].status = statuses.local_queue;
            }
            
            //Push each item to queue
            for (i = 0; i < $scope.lost_treasure.entries.length; i++) {
                $scope.lost_treasure.methods.push($scope.lost_treasure.entries[i]);
                $scope.lost_treasure.entries[i].status = statuses.remote_queue;
            }
            
            //Poll result for each scenario
            i = 0;
            while (i < $scope.lost_treasure.entries.length) {
                //$scope.lost_treasure.methods.push($scope.lost_treasure.entries[i]);
                if(i === 0) {
                    $scope.lost_treasure.entries[i].meta.loading = false;
                    $scope.lost_treasure.entries[i].status = statuses.done;
                }
                i++;
                
            }
        
        }
    };
    
    $scope.lost_treasure.mock_entries = [
        {
            'batch': $scope.lost_treasure.counters.batch,
            'id': $scope.lost_treasure.methods.generate_id(),
            'sequence_no': $scope.lost_treasure.counters.sequence_no++,
            'ref_no': 1,
            'test_date': '2/26/2015',
            'scenario': 'Subscriber texts invalid keyword Catch All Reply',
            'keyword': 'INVALID',
            'a_number':'09273299820',
            'b_number':'2346',
            'time_sent': null,
            'time_received': null,
            'beginning_balance': null,
            'ending_balance': null,
            'amount_charged': null,
            'expected_charge': 2.50,
            'expected_result':'Sorry, you sent an invalid keyword. Text CHECK to 2346 for free to know your services. To Activate your MMS, txt GO to 2951 .Need help on 2346 downloads? Call (02)892-9999, Mon-Fri 9am-5pm. Thank you',
            'actual_result': null,
            'pass_fail': null,
            'remarks': null,
            'meta': {
                'loading': false
            }
         },
         {
            'batch': $scope.lost_treasure.counters.batch,
            'id': $scope.lost_treasure.methods.generate_id(),
            'sequence_no': $scope.lost_treasure.counters.sequence_no++,             
            'ref_no': 2,
            'test_date': '2/26/2015',
            'scenario': 'Without Subscriptions',
            'keyword': 'CHECK',
            'a_number':'09273299820',
            'b_number':'2346',
            'time_sent': null,
            'time_received': null,
            'beginning_balance': null,
            'ending_balance': null,
            'amount_charged': null,
            'expected_charge': 0,
            'expected_result':'You do not have any subscriptions on 2346. This text is FREE. Get hot music and game downloads for your mobile visit http://dloadstation.com browsing is FREE. Questions? Call 892-9999 Mon-Fri 9am-5pm.',
            'actual_result': null,
            'pass_fail': null,
            'remarks': null,
            'meta': {
                'loading': false
            }
        },
        {
            'batch': $scope.lost_treasure.counters.batch,
            'id': $scope.lost_treasure.methods.generate_id(),
            'sequence_no': $scope.lost_treasure.counters.sequence_no++,            
            'ref_no': 3,
            'test_date': '2/26/2015',
            'scenario': 'Info message about the service indicating opt-in command, push frequency and tariff, opt-out command and service hotline.',
            'keyword': 'PCLUBINFO',
            'a_number':'09273299820',
            'b_number':'2346',
            'time_sent': null,
            'time_received': null,
            'beginning_balance': null,
            'ending_balance': null,
            'amount_charged': null,
            'expected_charge': 0,
            'expected_result':'PISO Club Service is your premium access to fun & latest MP3’s, Stickers, Quote and more! To enjoy this, reply ON PISOCLUB to 2346 for only P1.00 daily. To cancel service, reply STOP PISOCLUB. For questions, call 8929999 Monday to Friday 9-5PM.',
            'actual_result': null,
            'pass_fail': null,
            'remarks': null,
            'meta': {
                'loading': false
            }
        }        
    ];
    
    $scope.lost_treasure.entries = $scope.lost_treasure.mock_entries;
    
  });
