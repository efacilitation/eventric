describe 'PubSub', ->

  PubSub = require './pub_sub'

  pubSub = null

  beforeEach ->
    pubSub = new PubSub


  describe '#subscribe', ->
    it 'should return a unique subscriber id', ->
      firstSubscribe = pubSub.subscribe 'SomeEvent', ->
      secondSubscribe = pubSub.subscribe 'SomeEvent', ->

      Promise.all [firstSubscribe, secondSubscribe]
      .then ([subscriberId1, subscriberId2]) ->
        expect(subscriberId1).to.be.a 'number'
        expect(subscriberId2).to.be.a 'number'
        expect(subscriberId1).not.to.equal subscriberId2


  describe '#publish', ->

    it 'should execute subscriber functions which subscribed for the published event', ->
      spy1 = sandbox.spy()
      spy2 = sandbox.spy()
      payload1 = {1: 1}
      payload2 = {2: 2}

      pubSub.subscribe 'Event1', spy1
      pubSub.subscribe 'Event2', spy2

      pubSub.publish 'Event1', payload1
      pubSub.publish 'Event2', payload2

      expect(spy1).to.have.been.calledWith payload1
      expect(spy2).to.have.been.calledWith payload2


    it 'should not execute subscriber functions which subscribed for other events', ->
      subscriberSpy = sandbox.spy()
      pubSub.subscribe 'Event1', subscriberSpy
      pubSub.publish 'Event2', {}
      expect(subscriberSpy).not.to.have.been.called


    it 'should wait to resolve for the executed subscriber functions given they return promises', ->
      subscriberStub1 = sandbox.stub().returns new Promise (resolve) -> setTimeout resolve, 15
      subscriberStub2 = sandbox.stub().returns new Promise (resolve) -> setTimeout resolve, 15

      pubSub.subscribe 'Event1', subscriberStub1
      pubSub.subscribe 'Event1', subscriberStub2

      pubSub.publish 'Event1', {}
      .then ->
        expect(subscriberStub1).to.have.been.called
        expect(subscriberStub2).to.have.been.called


    it 'should execute all subscriber functions in parallel even if they are asynchronous', ->
      subscriberStub1 = sandbox.stub().returns new Promise ->
      subscriberStub2 = sandbox.stub().returns new Promise ->

      pubSub.subscribe 'Event1', subscriberStub1
      pubSub.subscribe 'Event1', subscriberStub2

      pubSub.publish 'Event1', {}
      expect(subscriberStub1).to.have.been.called
      expect(subscriberStub2).to.have.been.called


  describe '#unsubscribe', ->

    it 'should unsubscribe the subscriber with the given subscriber id', ->
      publishedEvent = {}
      spy = sandbox.spy()
      pubSub.subscribe 'SomeEvent', spy
      .then (subscriberId) ->
        pubSub.unsubscribe subscriberId
      .then ->
        pubSub.publish 'SomeEvent', publishedEvent
      .then ->
        expect(spy).not.to.have.been.called


    it 'should not unsubscribe subscribers with another id than the given one', ->
      spy = sandbox.spy()
      pubSub.subscribe 'Event1', spy
      pubSub.unsubscribe 'unknown-subscriber-id'
      pubSub.publish 'Event1', {}
      expect(spy).to.have.been.called


  describe '#destroy', ->

    it 'should reject with an error given the publish method is called afterwards', ->
      pubSub.destroy()
      .then ->
        pubSub.publish 'Event1', foo: 'bar'
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'destroyed'
        expect(error.message).to.contain 'Event1'
        expect(error.message).to.match /"foo"\:\s*"bar"/


    it 'should wait to resolve given there are ongoing publish operations', ->
      stub1 = sandbox.stub().returns new Promise (resolve) -> setTimeout resolve, 15
      stub2 = sandbox.stub().returns new Promise (resolve) -> setTimeout resolve, 15
      pubSub.subscribe 'Event1', stub1
      pubSub.subscribe 'Event2', stub2
      pubSub.publish 'Event1', {}
      pubSub.publish 'Event2', {}
      pubSub.destroy()
      .then ->
        expect(stub1).to.have.been.called
        expect(stub2).to.have.been.called


    it 'should correctly resolve given previous publish operations rejected', ->
      stub1 = sandbox.stub().returns new Promise (resolve, reject) -> reject()
      pubSub.subscribe 'Event1', stub1
      pubSub.publish 'Event1', {}
      pubSub.destroy()
      .then ->
        expect(stub1).to.have.been.called
