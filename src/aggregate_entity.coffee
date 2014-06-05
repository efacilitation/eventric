eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
AggregateEntity = eventric.require 'AggregateEntity'

eventric.require 'HelperObserve'

class AggregateEntity

  constructor: (name, @_props = {}) ->
    @_entityName        = name
    @_isNew             = false
    @_propsChanged      = {}
    @_domainEvents      = []
    @_entityClasses     = {}
    @_trackPropsChanged = true
    @_defineProperties()
    @_observerOpen()


  initialize: ->
    @id = @_generateUid()
    @_isNew = true
    @_observerDiscard()


  _defineProperties: ->
    for key, value of @_props
      Object.defineProperty @, key,
        get: -> @_props[key]
        set: (newValue) -> @_set key, newValue


  _observerOpen: ->
    @_observer = new ObjectObserver @
    @_observer.open (added, removed, changed, getOldValueFn) =>
      Object.keys(added).forEach (property) =>
        @_set property, added[property]

      Object.keys(changed).forEach (property) =>
        @_set property, changed[property]


  _observerDiscard: ->
    @_observer.discardChanges()


  _observerClose: ->
    @_observer.close()


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  getMetaData: ->
    id: @id
    name: @_entityName


  getChanges: ->
    @_observer.deliver()

    changes = {}
    if Object.keys(@_propsChanged).length > 0
      changes = @_propsChanged

    changes


  clearChanges: ->
    @_observerClose()
    @_propsChanged = {}
    # TODO: clear changes of nested entities
    @_observerOpen()


  applyChanges: (changes, params={}) ->
    @_observerClose()
    oldTrackPropsChanged = @_trackPropsChanged
    @_trackPropsChanged = false
    @_applyChanges changes
    @_trackPropsChanged = oldTrackPropsChanged

    @_observerOpen()


  _applyChanges: (propChanges) ->

    for propName, propValue of propChanges
      @[propName] = propValue


  applyProps: (props) ->
    @[key] = value for key, value of props


  getEntityClass: (className) ->
    EntityClass = @_entityClasses[className] ? false


  registerEntityClass: (className, Class) ->
    @_entityClasses[className] = Class


  _set: (key, value) ->
    @_props ?= {}
    @_propsChanged ?= {}

    if @_shouldTrackChangePropertiesFor key, value
     @_propsChanged[key] = value

    @_props[key] = value


  _get: (key) ->
    @_props[key]


  _shouldTrackChangePropertiesFor: (key, value) ->
    @_trackPropsChanged and key != 'id'


module.exports = AggregateEntity
