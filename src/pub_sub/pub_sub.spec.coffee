describe 'PubSub', ->
  PubSub = require 'eventric/src/pub_sub'

  pubSub = null
  beforeEach ->
    pubSub = new PubSub


  describe '#subscribe', ->
    it 'should return an unique subscriber id', ->
      subscriberId1 = pubSub.subscribe 'SomeEvent', ->
      subscriberId2 = pubSub.subscribe 'SomeEvent', ->
      expect(subscriberId1).to.be.a 'number'
      expect(subscriberId2).to.be.a 'number'
      expect(subscriberId1).not.to.equal subscriberId2


    it 'should subscribe to the event with given name', (done) ->
      publishedEvent = {}
      pubSub.subscribe 'SomeEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      pubSub.publish 'SomeEvent', publishedEvent


  describe '#subscribeAsync', ->
    it 'should return an unique subscriber id', ->
      subscriberId1 = pubSub.subscribeAsync 'SomeEvent', ->
      subscriberId2 = pubSub.subscribeAsync 'SomeEvent', ->
      expect(subscriberId1).to.be.a 'number'
      expect(subscriberId2).to.be.a 'number'
      expect(subscriberId1).not.to.equal subscriberId2


    it 'should subscribe to the event with given name', (done) ->
      publishedEvent = {}
      pubSub.subscribeAsync 'SomeEvent', (event) ->
        expect(event).to.equal publishedEvent
        done()
      pubSub.publish 'SomeEvent', publishedEvent


  describe '#publish', ->
    it 'should notify all subscribers in registration order', (done) ->
      executedSubscriber = []
      pubSub.subscribe 'SomeEvent', ->
        executedSubscriber.push 'first'
      pubSub.subscribe 'SomeEvent', ->
        executedSubscriber.push 'second'
        expect(executedSubscriber).to.deep.equal ['first', 'second']
        done()
      pubSub.publish 'SomeEvent'


    it 'should immediately call back even though subscribers may be asynchronous', (done) ->
      spy = sandbox.spy()
      handler = (event, done) -> setTimeout spy, 50
      pubSub.subscribeAsync 'SomeEvent', handler
      pubSub.publish 'SomeEvent', {}, ->
        expect(spy).not.to.have.been.called
        done()


  describe '#publishAsync', ->
    it 'should wait for async subscribers to invoke the done callback before executing the next handler', (done) ->
      greeting = ''
      handler1 = (event, done) ->
        setTimeout ->
          greeting += 'Hello '
          done()
        , 50
      handler2 = ->
        greeting += 'World'
      pubSub.subscribeAsync 'SomeEvent', handler1
      pubSub.subscribe 'SomeEvent', handler2
      pubSub.publishAsync 'SomeEvent', {}, ->
        expect(greeting).to.equal 'Hello World'
        done()


    it 'should execute synchronous handlers in series', (done) ->
      spy1 = sandbox.spy()
      spy2 = sandbox.spy()
      handler1 = -> spy1()
      handler2 = -> spy2()
      pubSub.subscribeAsync 'SomeEvent', handler1
      pubSub.subscribeAsync 'SomeEvent', handler2
      pubSub.publish 'SomeEvent', {}, ->
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
      pubSub.subscribeAsync 'SomeEvent', handler1
      pubSub.subscribeAsync 'SomeEvent', handler2
      pubSub.publishAsync 'SomeEvent', {}, ->
        expect(callCount).to.equal 2
        done()


  describe '#unsubscribe', ->
    it 'should unsubscribe the subscriber and not notify it anymore', (done) ->
      publishedEvent = {}
      subscriberFn = sandbox.spy()
      subscriberId = pubSub.subscribe 'SomeEvent', subscriberFn
      pubSub.unsubscribe subscriberId
      pubSub.publishAsync 'SomeEvent', publishedEvent, ->
        expect(subscriberFn).not.to.have.been.called
        done()
