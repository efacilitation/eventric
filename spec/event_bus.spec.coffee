describe 'EventBus', ->
  EventBus = require 'eventric/src/event_bus'

  eventBus = null
  beforeEach ->
    eventBus = new EventBus


  describe '#subscribeToDomainEvent', ->
    it 'should subscribe to the event with given event name', (done) ->
      publishedEvent = name: 'SomeEvent'
      eventBus.subscribeToDomainEvent 'SomeEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      eventBus.publishDomainEvent publishedEvent, ->


  describe '#publishDomainEvent', ->
    it 'should always publish a generic "DomainEvent" event', (done) ->
      publishedEvent = name: 'SomeEvent'
      eventBus.subscribeToDomainEvent 'DomainEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      eventBus.publishDomainEvent publishedEvent, ->


    it 'should execute all subscribed handlers in registration order', (done) ->
      callCount = 0
      eventBus.subscribeToDomainEvent 'SomeEvent', ->
        callCount++
      eventBus.subscribeToDomainEvent 'SomeEvent', ->
        callCount++
        expect(callCount).to.equal 2
        done()
      eventBus.publishDomainEvent name: 'SomeEvent', ->


    it 'should immediately call back even though handlers may be asynchronous', (done) ->
      spy = sandbox.spy()
      handler1 = (event, done) -> setTimeout spy, 50
      eventBus.subscribeToDomainEvent 'SomeEvent', handler1, isAsync: true
      eventBus.publishDomainEvent ame: 'SomeEvent', ->
        expect(spy).not.to.have.been.called
        done()


  describe '#publishDomainEventAndWait', ->
    it 'should always publish a generic "DomainEvent" event', (done) ->
      publishedEvent = name: 'SomeEvent'
      eventBus.subscribeToDomainEvent 'SomeEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      eventBus.publishDomainEventAndWait publishedEvent, ->


    it 'should wait for async handlers to invoke the done callback before executing the next handler', (done) ->
      greeting = ''
      handler1 = (event, done) ->
        setTimeout ->
          greeting += 'Hello '
          done()
        , 50
      handler2 = ->
        greeting += 'World'
      eventBus.subscribeToDomainEvent 'SomeEvent', handler1, isAsync: true
      eventBus.subscribeToDomainEvent 'SomeEvent', handler2
      eventBus.publishDomainEventAndWait name: 'SomeEvent', ->
        expect(greeting).to.equal 'Hello World'
        done()


    it 'should execute synchronous handlers in series', (done) ->
      spy1 = sandbox.spy()
      spy2 = sandbox.spy()
      handler1 = -> spy1()
      handler2 = -> spy2()
      eventBus.subscribeToDomainEvent 'SomeEvent', handler1
      eventBus.subscribeToDomainEvent 'SomeEvent', handler2
      eventBus.publishDomainEventAndWait name: 'SomeEvent', ->
        expect(spy1).to.have.been.called
        expect(spy2).to.have.been.called
        done()


    it 'should only call back when all handlers have finished', (done) ->
      callCount = 0
      handler1 = (event, done) ->
        setTimeout ->
          callCount++
          done()
        , 25
      handler2 = (event, done) ->
        setTimeout ->
          callCount++
          done()
        , 25
      eventBus.subscribeToDomainEvent 'SomeEvent', handler1, isAsync: true
      eventBus.subscribeToDomainEvent 'SomeEvent', handler2, isAsync: true
      eventBus.publishDomainEventAndWait name: 'SomeEvent', ->
        expect(callCount).to.equal 2
        done()