describe 'RemoteRepositoryService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  RemoteService           = eventric 'RemoteService'
  RemoteRepositoryService = eventric 'RemoteRepositoryService'

  describe '#rpc', ->

    class ExampleRepository
    remoteRepositoryService = null
    remoteServiceStub = null
    rpcPayload = null

    beforeEach ->
      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteServiceStub.rpc.yields null
      remoteRepositoryService = new RemoteRepositoryService remoteServiceStub
      remoteRepositoryService.registerClass 'ExampleRepository', ExampleRepository

      rpcPayload =
        class: 'ExampleRepository'
        method: 'exampleMethod'
        params: [
          'exampleParams'
        ]

    it 'should call the RemoteServiceAdapter', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, result) ->
        expect(result).to.be.a ExampleRepository
        done()

    it 'should convert responses to its corresponding class instance', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, result) ->
        expect(remoteServiceStub.rpc.calledWith rpcPayload).to.be.ok()
        done()