EventricDocs = angular.module("EventricDocs", [
  
  'EventricDocs.Controller.DocsPageCtrl'
  'EventricDocs.Controller.ApplicationCtrl'
  
  'pagesData'
  'ui.router'
])


.config ($stateProvider, $urlRouterProvider) ->
  # Now set up the states
  $stateProvider.state "docs",
    url: "/docs/:moduleName/:functionName"
    templateUrl: 'src/docs_page/docs_page.ng.html'
    controller: 'DocsPageCtrl'

  $urlRouterProvider.otherwise("/")
  return



angular.module("EventricDocs.Controller.ApplicationCtrl", [])

.controller "ApplicationCtrl", [
  "$scope", "DOC_PAGES"
  ($scope, DOC_PAGES) ->
    $scope.DOC_PAGES = DOC_PAGES
]