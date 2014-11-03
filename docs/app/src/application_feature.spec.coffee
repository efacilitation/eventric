describe.only 'Docs', ->

  it 'should load the api template if we change the state', ->

    angular.mock.module ($provide) ->
      $provide.value 'pagesData', {}

    angular.mock.module 'EventricDocs'

    angular.mock.inject ($state, $rootScope, $compile) ->
      $state.go 'api'

      $scope = $rootScope.$new()
      $viewElement = $compile('<main><div ui-view></div></main>')($scope)

      expect($viewElement.find('.api').length).to.equal 1