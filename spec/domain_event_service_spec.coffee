describe 'DomainEventService', ->

  sinon      = require 'sinon'
  expect     = require 'expect.js'
  eventric   = require 'eventric'

  DomainEventService = eventric 'DomainEventService'

  sandbox = null
  eventStore = null
  domainEventService = null
  beforeEach ->
    sandbox = sinon.sandbox.create()
    class EventStore
      find: ->
      save: ->
    eventStore = sinon.createStubInstance EventStore
    eventStore.save.yields null
    domainEventService = new DomainEventService eventStore

  afterEach ->
    sandbox.restore()

  it 'should have extended Backbone.Events', ->
    expect(domainEventService.trigger).to.be.ok()

  describe '#saveAndTrigger', ->

    domainEvent = null
    beforeEach ->
      domainEvent =
        name: 'testMethod'
        aggregate:
          id: 1
          name: 'Example'
          changed:
            props:
              name: 'John'


    it 'should tell the EventStore to save the DomainEvent', (done) ->
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(eventStore.save.calledOnce).to.be.ok()
        done()

    it 'should trigger the given DomainEvent', (done) ->
      triggerSpy = sandbox.spy domainEventService, 'trigger'
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(triggerSpy.calledWith 'DomainEvent', domainEvent).to.be.ok()
        expect(triggerSpy.calledWith 'Example', domainEvent).to.be.ok()
        expect(triggerSpy.calledWith 'Example/1', domainEvent).to.be.ok()
        expect(triggerSpy.calledWith 'Example:testMethod', domainEvent).to.be.ok()
        expect(triggerSpy.calledWith 'Example:testMethod/1', domainEvent).to.be.ok()
        done()