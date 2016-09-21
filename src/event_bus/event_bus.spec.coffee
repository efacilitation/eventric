describe 'EventBus', ->

  DomainEvent = null
  eventBus = null

  beforeEach ->
    EventBus = require './'
    DomainEvent = require 'eventric/domain_event'
    eventBus = new EventBus


  describe 'publishing a domain event', ->

    it 'should call the handler with the domain event given it subscribed for all domain events', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      handlerFunction = sandbox.stub()
      eventBus.subscribeToAllDomainEvents handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.been.calledWith domainEvent


    it 'should call the handler with the domain event given it subscribed for the correct domain event name', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      handlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.been.calledWith domainEvent


    it 'should call the handler with the domain given it subscribed for the correct domain event name and aggregate id', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
        aggregate:
          id: 'aggregate-1'
      handlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEventWithAggregateId 'DomainEventName', 'aggregate-1', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.been.calledWith domainEvent


    it 'should not call the handler function given it subscribed for a domain event with another name', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      handlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEvent 'AnotherDomainEventName', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.not.been.called


    it 'should not call the handler function given it subscribed for the correct domain event name but wrong aggregate id', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
        aggregate:
          id: 'aggregate-1'
      handlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEventWithAggregateId 'DomainEventName', 'aggregate-2', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.not.been.called


    it 'should not call the handler function given it subscribed for the correct aggregate id but wrong domain event name', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
        aggregate:
          id: 'aggregate-1'
      handlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEventWithAggregateId 'AnotherDomainEventName', 'aggregate-1', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.not.been.called


    it 'should call all handler functions given they subscribed for the correct domain event', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      handlerFunction = sandbox.stub()
      anotherHandlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.subscribeToDomainEvent 'DomainEventName', anotherHandlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.been.called
        expect(anotherHandlerFunction).to.have.been.called


    it 'should reject with an error given the handler function throws an error', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      thrownError = new Error
      handlerFunction = -> throw thrownError
      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .catch (receivedError) ->
        expect(receivedError).to.equal thrownError


    it 'should reject with an error given the handler function reject with an error', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      rejectedError = new Error
      handlerFunction = -> Promise.reject rejectedError
      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .catch (receivedError) ->
        expect(receivedError).to.equal rejectedError


    it 'should wait to resolve given the handler function takes some time to resolve', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      handlerFunctionHasFinished = false
      handlerFunction = ->
        new Promise (resolve) ->
          setTimeout ->
            handlerFunctionHasFinished = true
            resolve()
          , 15
      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunctionHasFinished).to.be.true


    it 'should wait to publish the domain event given a previous publish operation is not finished yet', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      anotherDomainEvent = new DomainEvent
        name: 'AnotherDomainEventName'

      handlerFinishedFunction = sandbox.stub()
      handlerFunction = ->
        new Promise (resolve) ->
          setTimeout ->
            handlerFinishedFunction()
            resolve()
          , 15

      anotherHandlerFunction = sandbox.stub()

      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.subscribeToDomainEvent 'AnotherDomainEventName', anotherHandlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
        eventBus.publishDomainEvent anotherDomainEvent
      .then ->
        expect(handlerFinishedFunction).to.have.been.calledBefore anotherHandlerFunction


    it 'should publish the domain event although a previous publish operation has failed', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      anotherDomainEvent = new DomainEvent
        name: 'AnotherDomainEventName'
      handlerFunction = -> Promise.reject new Error
      anotherHandlerFunction = sandbox.stub()
      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.subscribeToDomainEvent 'AnotherDomainEventName', anotherHandlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
        eventBus.publishDomainEvent anotherDomainEvent
      .then ->
        expect(anotherHandlerFunction).to.have.been.called


    it 'should not call the handler function given it unsubscribed after subscribing', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
        aggregate: id: 'aggregate-1'
      handlerFunction = sandbox.stub()
      Promise.all [
        eventBus.subscribeToAllDomainEvents handlerFunction
        eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
        eventBus.subscribeToDomainEventWithAggregateId 'DomainEventName', 'aggregate-1', handlerFunction
      ]
      .then (subscriberIds) ->
        Promise.all subscriberIds.map (subscriberId) -> eventBus.unsubscribe subscriberId
      .then ->
        eventBus.publishDomainEvent domainEvent
      .then ->
        expect(handlerFunction).to.have.not.been.called


  describe 'destroying the event bus', ->

    it 'should reject with an error when publishing after destroying the event bus', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
        payload: foo: 'bar'
        aggregate: id: 'aggregate-123'
      eventBus.destroy()
      .then ->
        eventBus.publishDomainEvent domainEvent
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'DomainEventName'
        expect(error.message).to.match /"foo"\s*:"bar"/
        expect(error.message).to.contain 'aggregate-123'


    it 'should wait to resolve given a previous publish operation has not finished yet', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'

      handlerFinishedFunction = sandbox.stub()
      handlerFunction = ->
        new Promise (resolve) ->
          setTimeout ->
            handlerFinishedFunction()
            resolve()
          , 15

      eventBus.subscribeToDomainEvent 'DomainEventName', handlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
        eventBus.destroy()
      .then ->
        expect(handlerFinishedFunction).to.have.been.called


    it 'should wait to resolve given a previous ongoing publish operation will trigger another publish operation', ->
      domainEvent = new DomainEvent
        name: 'DomainEventName'
      anotherDomainEvent = new DomainEvent
        name: 'AnotherDomainEventName'

      handleFunction =  ->
        new Promise (resolve) ->
          setTimeout ->
            eventBus.publishDomainEvent anotherDomainEvent
            resolve()
          , 15
      anotherHandlerFunction = sandbox.stub()

      eventBus.subscribeToDomainEvent 'DomainEventName', handleFunction
      .then ->
        eventBus.subscribeToDomainEvent 'AnotherDomainEventName', anotherHandlerFunction
      .then ->
        eventBus.publishDomainEvent domainEvent
        eventBus.destroy()
      .then ->
        expect(anotherHandlerFunction).to.have.been.called
