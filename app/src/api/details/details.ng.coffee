detailsModule = angular.module("eventric.app.api.details", [])

.filter 'unsafe', ($sce) ->
  return (
    (val) ->
      return $sce.trustAsHtml val if val
  )


.directive "apiDetails", ($stateParams, $http, API_OVERVIEW) ->
  restrict: "E"
  templateUrl: "api/details/details.ng.html"
  link: (scope) ->
    # Define API Scope
    scope.api = {}

    # Load JSON-file
    if $stateParams.functionName and $stateParams.moduleName
      $http.get '/apis/' + $stateParams.moduleName + '/' + $stateParams.functionName + '.json'
      .success (JSON_CONTENT) ->
        scope.api = JSON_CONTENT
        return

    return


module.exports = detailsModule.name