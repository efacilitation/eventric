describe 'API', ->

  $rootScope = null
  $viewElement = null
  $timeout = null
  $httpBackend = null
  location = null
  compileUiView = ($rootScope, $compile) ->
    $scope = $rootScope.$new()
    $compile('<main selection><div ui-view><div ui-view><div ui-view></div></div></div></main>')($scope)


  beforeEach ->
    angular.module 'pagesData', []
      .value 'API_OVERVIEW',
        ExampleModule: [{
          name: 'ExampleFunctionName'
          module: 'ExampleModule'
        }]
    angular.mock.module 'pagesData'

    angular.mock.module require 'eventric-app/src'
    $state = null
    angular.mock.inject (_$state_, $location, _$rootScope_, $compile, _$timeout_, $injector) ->
      $state = _$state_
      $timeout = _$timeout_
      $rootScope = _$rootScope_
      $viewElement = compileUiView $rootScope, $compile
      $httpBackend = $injector.get '$httpBackend'

    new Promise (resolve, reject) ->
      $state.go 'api'
      $timeout.flush()
      setTimeout ->
        resolve()


  it 'should render the given api-name to the DOM', ->
    $scope = $viewElement.find('.api-container').scope()
    api =
      name: "Test-Api-Function-Name"
    $scope.api = api
    $scope.$apply()
    expect($viewElement.find('h1').text()).to.equal api.name


  it 'should show the api-details by click on the navigation-item', ->

    api =
      name: "Test-Api-Function-Name"

    $httpBackend.whenGET('/apis/ExampleModule/ExampleFunctionName.json').respond api

    $viewElement.find('.nav-sidebar a[href="/api/ExampleModule/ExampleFunctionName"]').click()
    $timeout.flush()
    $httpBackend.flush()

    # console.log $viewElement
    expect($viewElement.find('h1').text()).to.equal api.name











