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
    new Promise (resolve, reject) =>
      subscriber =
        eventName: eventName
        subscriberFn: subscriberFn
        subscriberId: @_getNextSubscriberId()
      @_subscribers.push subscriber
      resolve subscriber.subscriberId


  ###*
  * @name publish
  * @module PubSub
  * @description Publish an Event
  *
  * @param {String} eventName Name of the Event
  * @param {Object} payload The Event payload to be published
  ###
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


  ###*
  * @name unsubscribe
  * @module PubSub
  * @description Unscribe from an Event
  *
  * @param {String} subscriberId SubscriberId
  ###
  unsubscribe: (subscriberId) ->
    new Promise (resolve, reject) =>
      @_subscribers = @_subscribers.filter (x) -> x.subscriberId isnt subscriberId
      resolve()


  _getNextSubscriberId: ->
    @_subscriberId++


module.exports = PubSub
