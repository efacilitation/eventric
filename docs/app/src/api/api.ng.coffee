docsModule = angular.module("EventricDocs.Controller.ApiCtrl", [])

.filter 'unsafe', ($sce) ->
  return (
    (val) ->
      return $sce.trustAsHtml val if val
  )


.controller "ApiCtrl", [
  "$scope", "$stateParams", "$http"
  ($scope, $stateParams, $http) ->

    # Define API Scope
    $scope.api = {}

    # Load JSON-file
    if $stateParams.functionName and $stateParams.moduleName
      $http.get '/apis/' + $stateParams.moduleName + '/' + $stateParams.functionName + '.json'
      .success (JSON_CONTENT) ->
        $scope.api = JSON_CONTENT
        false
]

module.exports = docsModule.name