describe 'EventBus', ->
  EventBus = require 'eventric/src/event_bus'

  eventBus = null
  beforeEach ->
    eventBus = new EventBus


  describe '#subscribe', ->
    it 'should subscribe to the event with given event name', (done) ->
      publishedEvent = {}
      eventBus.subscribe 'SomeEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      eventBus.publish 'SomeEvent', publishedEvent, ->


  describe '#publish', ->
    it 'should always publish a generic "DomainEvent" event', (done) ->
      publishedEvent = {}
      eventBus.subscribe 'DomainEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      eventBus.publish 'SomeEvent', publishedEvent, ->


    it 'should execute all subscribed handlers in registration order', (done) ->
      callCount = 0
      eventBus.subscribe 'SomeEvent', ->
        callCount++
      eventBus.subscribe 'SomeEvent', ->
        callCount++
        expect(callCount).to.equal 2
        done()
      eventBus.publish 'SomeEvent', {}, ->


    it 'should immediately call back even though handlers may not be finished yet', (done) ->
      spy = sandbox.spy()
      handler1 = (event, done) -> setTimeout spy, 50
      eventBus.subscribe 'SomeEvent', handler1
      eventBus.publish 'SomeEvent', {}, ->
        expect(spy).not.to.have.been.called
        done()


  describe '#publishAndWait', ->
    it 'should always publish a generic "DomainEvent" event', (done) ->
      publishedEvent = {}
      eventBus.subscribe 'SomeEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      eventBus.publishAndWait 'SomeEvent', publishedEvent, ->


    it 'should wait for async handlers to invoke the done callback before executing the next handler', (done) ->
      greeting = ''
      handler1 = (event, done) ->
        setTimeout ->
          greeting += 'Hello '
          done()
        , 50
      handler2 = ->
        greeting += 'World'
      eventBus.subscribe 'SomeEvent', handler1
      eventBus.subscribe 'SomeEvent', handler2
      eventBus.publishAndWait 'SomeEvent', {}, ->
        expect(greeting).to.equal 'Hello World'
        done()


    it 'should assume handlers to be synchronous when they don´t expect a done callback argument', ->
      spy1 = sandbox.spy()
      spy2 = sandbox.spy()
      handler1 = -> spy1()
      handler2 = -> spy2()
      eventBus.subscribe 'SomeEvent', handler1
      eventBus.subscribe 'SomeEvent', handler2
      eventBus.publishAndWait 'SomeEvent', {}, ->
        expect(spy1).to.have.been.called
        expect(spy2).to.have.been.called
        done()


    it 'should only call back when all handlers have finished', ->
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
      eventBus.subscribe 'SomeEvent', handler1
      eventBus.subscribe 'SomeEvent', handler2
      eventBus.publishAndWait 'SomeEvent', {}, ->
        expect(callCount).to.equal 2
        done()