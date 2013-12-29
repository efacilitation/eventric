describe 'DomainEventService', ->

  sinon      = require 'sinon'
  expect     = require 'expect'
  eventric   = require 'eventric'

  DomainEventService = eventric 'DomainEventService'

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  it 'should have extended Backbone.Events', ->
    expect(DomainEventService.trigger).to.be.ok()

  describe '#handle', ->

    domainEvent = null
    beforeEach ->
      domainEvent =
        name: 'testEvent'
        data:
          id: 1
          model: 'Example'
        changed:
          props:
            name: 'John'


    it 'should call _applyChanges with given DomainEvents on active matching ReadModels', ->
      class ExampleReadModel
        _applyChanges: sinon.stub()

      exampleReadModel = new ExampleReadModel

      DomainEventService._handlers =
        'Example':
          1: [
            exampleReadModel
          ]

      DomainEventService.handle [domainEvent]

      expect(exampleReadModel._applyChanges.calledWith domainEvent._changed).to.be.ok()

    it 'should trigger the given DomainEvent', ->
      triggerSpy = sandbox.spy DomainEventService, 'trigger'
      DomainEventService.handle [domainEvent]
      expect(triggerSpy.calledWith 'DomainEvent', domainEvent).to.be.ok()

    it 'should store the DomainEvent into a local cache', ->
      storeInCacheSpy = sandbox.spy DomainEventService, '_storeInCache'
      DomainEventService.handle [domainEvent]
      expect(storeInCacheSpy.calledWith domainEvent).to.be.ok()