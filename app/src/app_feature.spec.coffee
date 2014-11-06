describe 'App', ->

  goToApi = null
  $timeout = null
  $viewElement = null
  compileUiView = ($rootScope, $compile) ->
    $scope = $rootScope.$new()
    $compile('<main selection><div ui-view><div ui-view><div ui-view></div></div></div></main>')($scope)


  beforeEach ->
    angular.module 'pagesData', []
      .value 'API_OVERVIEW', {}
    angular.mock.module 'pagesData'

    angular.mock.module require 'eventric-app/src'
    angular.mock.inject ($state, $rootScope, $compile, _$timeout_) ->
      $timeout = _$timeout_
      $viewElement = compileUiView $rootScope, $compile

      goToApi = ->
        new Promise (resolve, reject) ->
          $state.go 'api'
          $timeout.flush()
          setTimeout ->
            resolve()


  it 'should load the api template if we change the state', ->
    goToApi()
    expect($viewElement.find('.api').length).to.equal 1