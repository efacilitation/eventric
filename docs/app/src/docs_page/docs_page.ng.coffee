angular.module("EventricDocs.Controller.DocsPageCtrl", [])

.controller "DocsPageCtrl", [
  "$scope", "$stateParams"
  ($scope, $stateParams) ->
    console.log $stateParams
    $scope.functionName = $stateParams.functionName
    $scope.functionView = "/views/"+$stateParams.functionName+".html"
    return
]
