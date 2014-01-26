describe.only 'RemoteRepositoryService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  AggregateEntity         = eventric 'AggregateEntity'
  RemoteService           = eventric 'RemoteService'
  RemoteRepositoryService = eventric 'RemoteRepositoryService'

  describe '#rpc', ->

    class ExampleAggregate extends AggregateEntity
    class ExampleRepository

    remoteRepositoryService = null
    remoteServiceStub = null
    rpcPayload = null

    beforeEach ->
      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteServiceStub.rpc.yields null, [
        name: '_snapshot'
        aggregate:
          id: 42
          name: 'ExampleAggregate'
          changed:
            props:
              name: 'John'
      ]

      remoteRepositoryService = new RemoteRepositoryService remoteServiceStub
      remoteRepositoryService.registerClass 'ExampleAggregate', ExampleAggregate

      rpcPayload =
        class: 'ExampleRepository'
        method: 'exampleMethod'
        params: [
          'exampleParams'
        ]

    it 'should convert rpc responses to its corresponding class instances', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, results) ->
        expect(results[0]).to.be.a ExampleAggregate
        done()

    it 'should apply changes on converted rpc responses', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, results) ->
        expect(results[0]._get 'name').to.be 'John'
        done()

    it 'should call the RemoteServiceAdapter', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, result) ->
        expect(remoteServiceStub.rpc.calledWith rpcPayload).to.be.ok()
        done()