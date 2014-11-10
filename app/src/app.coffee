eventricApp = angular.module('eventric.app', [
  require 'eventric-app/src/api/api.ng'
  require 'eventric-app/src/api/comments/comments.ng'
  require 'eventric-app/src/api/navigation/navigation.ng'
  require 'eventric-app/src/api/details/details.ng'
  'pagesData'
  'ui.router'
])

.config ($stateProvider, $urlRouterProvider, $locationProvider) ->

  # Now set up the states
  $stateProvider.state 'home',
    url: '/home'
    templateUrl: 'home/home.ng.html'

  $stateProvider.state 'api',
    url: '/api/:moduleName/:functionName'
    templateUrl: 'api/api.ng.html'
    controller: 'ApiController'

  $locationProvider.hashPrefix '!'

  return


module.exports = eventricApp.name