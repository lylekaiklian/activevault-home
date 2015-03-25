'use strict';

/**
 * @ngdoc function
 * @name frontendYoApp.controller:MainControllerCtrl
 * @description
 * # MainControllerCtrl
 * Controller of the frontendYoApp
 */
angular.module('frontendYoApp')
  .controller('MainControllerCtrl', function ($scope) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });
