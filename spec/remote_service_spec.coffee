describe 'RemoteService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  RemoteService = eventric 'RemoteService'

  rpcPayload = null
  beforeEach ->
    rpcPayload =
      class: 'ExampleAggregate'
      method: 'exampleMethod'
      params: [
        'exampleParams'
      ]

  describe '#rpc', ->

    it 'call the rpc method on the RemoteServiceAdapter with the given parameters', (done) ->

      class ExampleRemoteServiceAdapter
        rpc: ->

      remoteServiceAdapter = sinon.createStubInstance ExampleRemoteServiceAdapter
      remoteServiceAdapter.rpc.yields null
      remoteService = new RemoteService remoteServiceAdapter
      remoteService.rpc rpcPayload, ->
        expect(remoteServiceAdapter.rpc.calledWith rpcPayload).to.be.ok()
        done()


  describe '#handle', ->

    it 'should execute the rpc', (done) ->

      class ExampleAggregate
        exampleMethod: ->

      exampleAggregate = sinon.createStubInstance ExampleAggregate
      exampleAggregate.exampleMethod.yields null, {}

      remoteService = new RemoteService
      remoteService.registerClass 'ExampleAggregate', exampleAggregate
      remoteService.handle rpcPayload, ->

        expect(exampleAggregate.exampleMethod.calledWith 'exampleParams').to.be.ok()
        done()