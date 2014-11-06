apiModule = angular.module("eventric.app.api", [
  'eventric.app.templates'
])
.filter 'unsafe', ($sce) ->
  return (
    (val) ->
      return $sce.trustAsHtml val if val
  )

.controller "ApiController", [
  "$scope", "$stateParams", "$http", "API_OVERVIEW"
  ($scope, $stateParams, $http, API_OVERVIEW) ->

    # Define API Scope
    $scope.api = {}
    $scope.API_OVERVIEW = API_OVERVIEW

    # Load JSON-file
    if $stateParams.functionName and $stateParams.moduleName
      $http.get '/apis/' + $stateParams.moduleName + '/' + $stateParams.functionName + '.json'
      .success (JSON_CONTENT) ->
        $scope.api = JSON_CONTENT
        false
]

module.exports = apiModule.name