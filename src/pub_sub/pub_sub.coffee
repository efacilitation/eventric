class PubSub

  constructor: ->
    @_subscribers = []
    @_subscriberId = 0
    @_pendingOperations = []


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
    @_addPendingOperation executeSubscriberFunctions
    executeSubscriberFunctions


  _getRelevantSubscribers: (eventName) ->
    if eventName
      @_subscribers.filter (subscriber) -> subscriber.eventName is eventName
    else
      @_subscribers


  _addPendingOperation: (pendingOperation) ->
    errorSuppressedPendingOperation = pendingOperation.catch ->
    @_pendingOperations.push errorSuppressedPendingOperation
    errorSuppressedPendingOperation.then =>
      @_pendingOperations.splice @_pendingOperations.indexOf(errorSuppressedPendingOperation), 1


  unsubscribe: (subscriberId) ->
    new Promise (resolve) =>
      @_subscribers = @_subscribers.filter (subscriber) -> subscriber.subscriberId isnt subscriberId
      resolve()


  _getNextSubscriberId: ->
    @_subscriberId++


  destroy: ->
    Promise.all(@_pendingOperations).then =>
      @publish = undefined


module.exports = PubSub
