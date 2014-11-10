navigationModule = angular.module("eventric.app.api.navigation", [])

.directive "navigation", (API_OVERVIEW) ->
  restrict: "E"
  templateUrl: "api/navigation/navigation.ng.html"
  link: (scope) ->
    scope.API_OVERVIEW = API_OVERVIEW
    return


module.exports = navigationModule.name