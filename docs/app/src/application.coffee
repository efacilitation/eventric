
EventricDocs = angular.module('EventricDocs', [
  require 'eventric/docs/app/src/api/api.ng'
  'EventricDocs.Controller.ApplicationCtrl'
  'pagesData'
  'ui.router'
])


.config ($stateProvider, $urlRouterProvider) ->
  # Now set up the states
  $stateProvider.state 'home',
    url: '/home'
    templateUrl: 'src/home/home.ng.html'

  $stateProvider.state 'api',
    url: '/api/:moduleName/:functionName'
    templateUrl: 'src/api/api.ng.html'
    controller: 'ApiCtrl'

  $locationProvider.hashPrefix '!'

  return


angular.module('EventricDocs.Controller.ApplicationCtrl', [])

.controller 'ApplicationCtrl', [
  '$scope', 'API_OVERVIEW'
  ($scope, API_OVERVIEW) ->
    $scope.API_OVERVIEW = API_OVERVIEW
]