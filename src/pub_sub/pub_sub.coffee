###*
* @name PubSub
* @module PubSub
* @description
*
* Publish and Subscribe to arbitrary Events
###
class PubSub

  constructor: ->
    @_subscribers = []
    @_subscriberId = 0
    @_nextTick = (args...) -> setTimeout args...


  ###*
  * @name subscribe
  * @module PubSub
  * @description Subscribe to an Event
  *
  * @param {String} eventName Name of the Event to subscribe to
  * @param {Function} subscriberFn Function to call when Event gets published
  ###
  subscribe: (eventName, subscriberFn) ->
    subscriber =
      eventName: eventName
      subscriberFn: subscriberFn
      subscriberId: @_getNextSubscriberId()
    @_subscribers.push subscriber
    subscriber.subscriberId


  ###*
  * @name subscribeAsync
  * @module PubSub
  * @description Subscribe asynchronously to an Event
  *
  * @param {String} eventName Name of the Event to subscribe to
  * @param {Function} subscriberFn Function to call when Event gets published
  ###
  subscribeAsync: (eventName, subscriberFn) ->
    subscriber =
      eventName: eventName
      subscriberFn: subscriberFn
      subscriberId: @_getNextSubscriberId()
      isAsync: true
    @_subscribers.push subscriber
    subscriber.subscriberId


  ###*
  * @name publish
  * @module PubSub
  * @description Publish an Event
  *
  * @param {String} eventName Name of the Event
  * @param {Object} payload The Event payload to be published
  ###
  publish: (eventName, payload, callback = ->) ->
    subscribers = @_getRelevantSubscribers eventName
    executeNextHandler = =>
      if subscribers.length is 0
        callback()
      else
        subscribers.shift().subscriberFn payload, ->
        @_nextTick executeNextHandler, 0
    @_nextTick executeNextHandler, 0


  ###*
  * @name publishAsync
  * @module PubSub
  * @description Publish an Event
  *
  * @param {String} eventName Name of the Event
  * @param {Object} payload The Event payload to asynchronously be published
  ###
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


  ###*
  * @name unsubscribe
  * @module PubSub
  * @description Unscribe from an Event
  *
  * @param {String} subscriberId SubscriberId
  ###
  unsubscribe: (subscriberId) ->
    @_subscribers = @_subscribers.filter (x) -> x.subscriberId isnt subscriberId


  _getNextSubscriberId: ->
    @_subscriberId++


module.exports = PubSub
