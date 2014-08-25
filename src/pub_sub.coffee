class PubSub

  constructor: ->
    @_subscribers = []
    @_subsrciberId = 0
    @_nextTick = (args...) -> setTimeout args...


  subscribe: (eventName, subscriberFn) ->
    subscriber =
      eventName: eventName
      subscriberFn: subscriberFn
      subscriberId: @_getNextSubscriberId()
    @_subscribers.push subscriber
    subscriber.subscriberId


  subscribeAsync: (eventName, subscriberFn) ->
    subscriber =
      eventName: eventName
      subscriberFn: subscriberFn
      subscriberId: @_getNextSubscriberId()
      isAsync: true
    @_subscribers.push subscriber
    subscriber.subscriberId


  publish: (eventName, payload, callback = ->) ->
    subscribers = @_getRelevantSubscribers eventName
    executeNextHandler = =>
      if subscribers.length is 0
        callback()
      else
        subscribers.shift().subscriberFn payload, ->
        @_nextTick executeNextHandler, 0
    @_nextTick executeNextHandler, 0


  publishAsync: (eventName, payload, callback = ->) ->
    subscribers = @_getRelevantSubscribers eventName
    executeNextHandler = =>
      if subscribers.length is 0
        callback()
      else
        subscriber = subscribers.shift()
        if subscriber.isAsync
          subscriber.subscriberFn payload, -> setTimeout executeNextHandler, 0
        else
          subscriber.subscriberFn payload
          @_nextTick executeNextHandler, 0
    @_nextTick executeNextHandler, 0


  _getRelevantSubscribers: (eventName) ->
    if eventName
      @_subscribers.filter (x) -> x.eventName is eventName
    else
      @_subscribers


  unsubscribe: (subscriberId) ->
    @_subscribers = @_subscribers.filter (x) -> x.subscriberId isnt subscriberId


  _getNextSubscriberId: ->
    @_subsrciberId++


module.exports = PubSub