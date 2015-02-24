describe 'PubSub', ->
  PubSub = require './'

  pubSub = null
  beforeEach ->
    pubSub = new PubSub


  describe '#subscribe', ->
    it 'should return an unique subscriber id', ->
      subscriberId1 = null
      subscriberId2 = null
      pubSub.subscribe('SomeEvent', ->)
      .then (_subscriberId1) ->
        subscriberId1 = _subscriberId1
        expect(subscriberId1).to.be.a 'number'

      pubSub.subscribe('SomeEvent', ->)
      .then (_subscriberId2) ->
        subscriberId2 = _subscriberId2
        expect(subscriberId2).to.be.a 'number'

        expect(subscriberId1).not.to.equal subscriberId2


    it 'should subscribe to the event with given name', (done) ->
      publishedEvent = {}
      pubSub.subscribe 'SomeEvent', (event) ->
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


  describe '#unsubscribe', ->
    it 'should unsubscribe the subscriber and not notify it anymore', (done) ->
      publishedEvent = {}
      subscriberFn = sandbox.spy()
      pubSub.subscribe 'SomeEvent', subscriberFn
      .then (subscriberId) ->
        pubSub.unsubscribe subscriberId
      .then ->
        pubSub.publish 'SomeEvent', publishedEvent
      .then ->
        expect(subscriberFn).not.to.have.been.called
        done()
