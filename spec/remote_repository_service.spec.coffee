describe 'RemoteRepositoryService', ->
  AggregateEntity         = eventric 'AggregateEntity'
  RemoteService           = eventric 'RemoteService'
  RemoteRepositoryService = eventric 'RemoteRepositoryService'

  class ExampleAggregate extends AggregateEntity

  class ExampleRepository
    exampleMethod: ->

  remoteRepositoryService = null
  remoteServiceStub = null
  rpcPayload = null
  exampleRepository = null

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

    exampleRepository = sinon.createStubInstance ExampleRepository

    remoteRepositoryService = new RemoteRepositoryService remoteServiceStub
    remoteRepositoryService.registerClass 'ExampleAggregate', ExampleAggregate
    remoteRepositoryService.registerClass 'ExampleRepository', exampleRepository

    rpcPayload =
      repository: 'ExampleRepository'
      method: 'exampleMethod'
      params: [
        'exampleParams'
      ]

  describe '#rpc', ->

    it 'should convert rpc responses to its corresponding class instances', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, results) ->
        expect(results[0]).to.be.an.instanceof ExampleAggregate
        done()

    it 'should apply changes on converted rpc responses', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, results) ->
        expect(results[0]._get 'name').to.equal 'John'
        done()

    it 'should call the RemoteService', (done) ->
      remoteRepositoryService.rpc rpcPayload, (err, result) ->
        expect(remoteServiceStub.rpc.calledWith 'RemoteRepositoryService', rpcPayload).to.be.true
        done()


  describe '#handle', ->

    it 'should execute the given method on the given repository', ->
      remoteRepositoryService.handle rpcPayload, ->
      expect(exampleRepository.exampleMethod.calledWith 'exampleParams').to.be.true

