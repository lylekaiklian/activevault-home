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
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });
