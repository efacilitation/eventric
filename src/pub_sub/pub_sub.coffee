class PubSub

  constructor: ->
    @_subscribers = []
    @_subscriberId = 0
    @_publishQueue = new Promise (resolve) -> resolve()


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
    @_enqueuePublishing executeSubscriberFunctions
    executeSubscriberFunctions


  _getRelevantSubscribers: (eventName) ->
    if eventName
      @_subscribers.filter (subscriber) -> subscriber.eventName is eventName
    else
      @_subscribers


  _enqueuePublishing: (publishOperation) ->
    @_publishQueue = @_publishQueue.then publishOperation


  unsubscribe: (subscriberId) ->
    new Promise (resolve) =>
      @_subscribers = @_subscribers.filter (subscriber) -> subscriber.subscriberId isnt subscriberId
      resolve()


  _getNextSubscriberId: ->
    @_subscriberId++


  destroy: ->
    @_publishQueue.then =>
      @subscribe = undefined
      @publish = undefined


module.exports = PubSub
