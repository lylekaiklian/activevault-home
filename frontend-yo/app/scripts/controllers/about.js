'use strict';

/**
 * @ngdoc function
 * @name frontendYoApp.controller:AboutCtrl
 * @description
 * # AboutCtrl
 * Controller of the frontendYoApp
 */
angular.module('frontendYoApp')
  .controller('AboutCtrl', function ($scope) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });
