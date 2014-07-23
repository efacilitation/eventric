describe 'RemoteService', ->
  RemoteService = require 'eventric/remote_service'

  rpc = null
  beforeEach ->
    rpc =
      service: 'RemoteExampleService'
      payload:
        class: 'ExampleAggregate'
        method: 'exampleMethod'
        params: [
          'exampleParams'
        ]


  describe '#rpc', ->

    it 'should call the rpc method on the RemoteServiceAdapter', (done) ->

      class ExampleRemoteServiceAdapter
        rpc: ->

      remoteServiceAdapter = sinon.createStubInstance ExampleRemoteServiceAdapter
      remoteServiceAdapter.rpc.yields null
      remoteService = new RemoteService remoteServiceAdapter
      remoteService.rpc 'RemoteExampleService', rpc.payload, ->
        expect(remoteServiceAdapter.rpc.calledWith rpc).to.be.true
        done()


  describe '#handle', ->

    it 'should call the handle function on the corresponding registered service', ->

      class RemoteExampleService
        handle: ->

      remoteExampleService = sinon.createStubInstance RemoteExampleService

      remoteService = new RemoteService
      remoteService.registerServiceHandler 'RemoteExampleService', remoteExampleService

      remoteService.handle rpc, ->
      expect(remoteExampleService.handle.calledWith rpc.payload).to.be.true
