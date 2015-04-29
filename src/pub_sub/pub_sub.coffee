class PubSub

  constructor: ->
    @_subscribers = []
    @_subscriberId = 0
    @_nextTick = (args...) -> setTimeout args...


  subscribe: (eventName, subscriberFn) ->
    new Promise (resolve, reject) =>
      subscriber =
        eventName: eventName
        subscriberFn: subscriberFn
        subscriberId: @_getNextSubscriberId()
      @_subscribers.push subscriber
      resolve subscriber.subscriberId


  publish: (eventName, payload) ->
    new Promise (resolve, reject) =>
      subscribers = @_getRelevantSubscribers eventName
      executeNextHandler = =>
        if subscribers.length is 0
          resolve()
        else
          subscribers.shift().subscriberFn payload, ->
          @_nextTick executeNextHandler, 0
      @_nextTick executeNextHandler, 0


  _getRelevantSubscribers: (eventName) ->
    if eventName
      @_subscribers.filter (x) -> x.eventName is eventName
    else
      @_subscribers


  unsubscribe: (subscriberId) ->
    new Promise (resolve, reject) =>
      @_subscribers = @_subscribers.filter (x) -> x.subscriberId isnt subscriberId
      resolve()


  _getNextSubscriberId: ->
    @_subscriberId++


module.exports = PubSub
