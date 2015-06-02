class PubSub

  constructor: ->
    @_subscribers = []
    @_subscriberId = 0
    @_pendingPublishOperations = []


  subscribe: (eventName, subscriberFunction) ->
    new Promise (resolve) =>
      subscriber =
        eventName: eventName
        subscriberFunction: subscriberFunction
        subscriberId: @_getNextSubscriberId()
      @_subscribers.push subscriber
      resolve subscriber.subscriberId


  publish: (eventName, payload) ->
    subscribers = @_getRelevantSubscribers eventName
    executeSubscriberFunctions = Promise.all subscribers.map (subscriber) -> subscriber.subscriberFunction payload
    @_addPendingPublishOperation executeSubscriberFunctions
    executeSubscriberFunctions


  _getRelevantSubscribers: (eventName) ->
    if eventName
      @_subscribers.filter (subscriber) -> subscriber.eventName is eventName
    else
      @_subscribers


  _addPendingPublishOperation: (publishOperation) ->
    @_pendingPublishOperations.push publishOperation
    publishOperation.then =>
      @_pendingPublishOperations.splice @_pendingPublishOperations.indexOf(publishOperation), 1


  unsubscribe: (subscriberId) ->
    new Promise (resolve) =>
      @_subscribers = @_subscribers.filter (subscriber) -> subscriber.subscriberId isnt subscriberId
      resolve()


  _getNextSubscriberId: ->
    @_subscriberId++


  destroy: ->
    Promise.all(@_pendingPublishOperations).then =>
      @publish = undefined


module.exports = PubSub
