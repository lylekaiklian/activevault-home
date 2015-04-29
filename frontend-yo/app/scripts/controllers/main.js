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
    // $scope.lost_treasure.csv_file = '';
    
    $scope.lost_treasure.selected = {};
    $scope.lost_treasure.type = [
        {
          'value':'sms',
          'label': 'SMS',
          'operations': [
            {'value':'send', 'label': 'send'},
            {'value':'check-balance', 'label': 'check-balance'}
          ],
          'conditions': [
            {'value':'like', 'label': 'like'},
            {'value':'equal', 'label': 'equal'}
          ]
        },
        {
          'value':'ussd',
          'label': 'USSD',
          'operations': [
            {'value':'check-balance', 'label': 'check-balance'},
            {'value':'check-promo', 'label': 'check-promo'}
          ],
          'conditions': [
            {'value':'like', 'label': 'like'},
            {'value':'equal', 'label': 'equal'}
          ]
        }
    ];

    $scope.lost_treasure.sms_operations = [
        {'value':'send', 'label': 'send'},
        {'value':'check-balance', 'label': 'check-balance'}
    ];

    $scope.lost_treasure.ussd_operations = [
        {'value':'check-promo', 'label': 'check-promo'},
        {'value':'check-account', 'label': 'check-account'}
    ];

    $scope.lost_treasure.sms_conditions = [
        {'value':'like', 'label': 'like'},
        {'value':'equal', 'label': 'equal'}
    ];

    $scope.lost_treasure.ussd_conditions = [
        {'value':'like', 'label': 'like'},
        {'value':'equal', 'label': 'equal'}
    ];


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

        import_scenario: function(csv_file){
          if(csv_file && csv_file.length){
            Upload.upload({
              url: 'url',
              file: csv_file
            }).progress(function(evt){
              console.log('upload on progress');
            }).success(function(data, status, headers, config){
              console.log('file ' + config.file.name + 'uploaded. Response: ' + data);
            });
          }
          console.log('AYAY!');
          console.log(csv_file);
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
                'type':'sms',
                'run_time': 0,
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


            /** Counters keep track of the sequence and batch of the scenarios **/
            $scope.lost_treasure.counters = {
                batch: new Date().getTime(),
                sequence_no: 1
            };
            
            //Set loading icons a-circling to give the user sense of movement and progress
            for (var i = 0; i < $scope.lost_treasure.entries.length; i++) {
                
                //Assign Batch Numer on Run time. This allows the scenarios to be run more than once.
                $scope.lost_treasure.entries[i].batch = $scope.lost_treasure.counters.batch;
                
                //Assign Sequence Number on Run time
                $scope.lost_treasure.entries[i].sequence_no = $scope.lost_treasure.counters.sequence_no++;
                
                //Reset run time clock 
                $scope.lost_treasure.entries[i].timer_start = null;
                
                $scope.lost_treasure.entries[i].meta.loading = true;
                $scope.lost_treasure.entries[i].status = statuses.local_queue;
            }
            
            //Push each item to queue
            for (i = 0; i < $scope.lost_treasure.entries.length; i++) {
                $scope.lost_treasure.methods.push($scope.lost_treasure.entries[i]);
                $scope.lost_treasure.entries[i].status = statuses.remote_queue;
            }
            
            //Poll result for each scenario until result is obtained.

            var infinite_poke = function(scenario_index) {
                
                //base case - reached end of line already.
                if ($scope.lost_treasure.entries.length <= scenario_index) { 
                    $scope.lost_treasure.running = false;
                    return; 
                }
                
                var batch = $scope.lost_treasure.entries[scenario_index].batch;
                var sequence_no = $scope.lost_treasure.entries[scenario_index].sequence_no;
                
                if (!$scope.lost_treasure.entries[scenario_index].timer_start) {
                 $scope.lost_treasure.entries[scenario_index].timer_start = new Date().getTime();
                }
                
                $http.head(endpoint + '/scenarios/' + batch + '/' + sequence_no)
                .success(function() {
                    $scope.lost_treasure.entries[scenario_index].meta.loading = false;
                    $scope.lost_treasure.entries[scenario_index].status = statuses.done;
                    $http.get(endpoint + '/scenarios/' + batch + '/' + sequence_no)
                    .success(function(data){
                        //unpack data from back-end
                        $scope.lost_treasure.entries[scenario_index].time_sent = data.time_sent;
                        $scope.lost_treasure.entries[scenario_index].time_received = data.time_received;
                        $scope.lost_treasure.entries[scenario_index].beginning_balance = data.beginning_balance;
                        $scope.lost_treasure.entries[scenario_index].ending_balance = data.ending_balance;
                        $scope.lost_treasure.entries[scenario_index].amount_charged = data.amount_charged;
                        $scope.lost_treasure.entries[scenario_index].actual_result = data.actual_result;
                        $scope.lost_treasure.entries[scenario_index].remarks = data.remarks;
                        $scope.lost_treasure.entries[scenario_index].timer_end = new Date().getTime();
                        $scope.lost_treasure.entries[scenario_index].run_time = 
                            $scope.lost_treasure.entries[scenario_index].timer_end - 
                            $scope.lost_treasure.entries[scenario_index].timer_start;
                        
                        if(data.pass_or_fail === 'true'){
                          $scope.lost_treasure.entries[scenario_index].pass_or_fail = true;
                        }else{
                          $scope.lost_treasure.entries[scenario_index].pass_or_fail = false;
                        }
                        console.log($scope.lost_treasure.entries[scenario_index].pass_or_fail)
                        infinite_poke(scenario_index + 1);
                    })
                     .error(function(){
                       //When, unfortunately, the GET fails for some weird reason     
                       setTimeout(function(){infinite_poke(scenario_index);}, 500); 
                    })                  
                    ;
                    
                })
                .error(function(){
                   //Retry after 0.5 seconds     
                   setTimeout(function(){infinite_poke(scenario_index);}, 500); 
                });
                
            };
  
       
        

            infinite_poke(0);

        
        }
    };
    
    $scope.lost_treasure.mock_entries = [
         {
            'ref_no': 1,
            'type': 'ussd',
             'operation': 'check-promo',
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
            'expected_result':
                'You do not have any subscriptions on 2346. This text is FREE. Get hot music and game downloads for your mobile visit http://dloadstation.com browsing is FREE. Questions? Call 892-9999 Mon-Fri 9am-5pm.',
            'actual_result': null,
            'pass_or_fail': null,
            'run_time': 0,
            'remarks': null,
            'ussd_command': '1, 3, 4, 6',
            'ussd_number': '*143#',
            'number_of_tries': '3',
            'condition': 'equal',
            'meta': {
                'loading': false
            }
        },
        {
            'ref_no': 2,
             'type': 'sms',
             'operation': 'check-balance',
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
            'expected_result':
                "PISO Club Service is your premium access to fun & latest MP3's, Stickers, Quote and more! To enjoy this, reply ON PISOCLUB to 2346 for only P1.00 daily.To cancel service, reply STOP PISOCLUB. For questions, call 8929999 Monday to Friday 9-5PM.",
            'actual_result': null,
            'pass_or_fail': null,
            'run_time': 0,
            'remarks': null,
            'ussd_command': null,
            'ussd_number': null,
            'number_of_tries': '5',
            'condition': 'like',
            'meta': {
                'loading': false
            }
        },
        /*
        1 Create a promo
                          2 Choose a gadget
                                           3 Create a promo + add UnliFB for P2!

4 NEW GoUNLI20
              5 GoUNLI25
                        6 Budget Promos
                                       7 What's Hot?
                                                    8 Manage registrations
                                                                          9 Back*/
        
    ];
    
    $scope.lost_treasure.entries = $scope.lost_treasure.mock_entries;
    
  });
