eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
DomainEvent     = eventric.require 'DomainEvent'

class Aggregate

  constructor: (name, definition, props) ->
    @_entityName        = name
    @_isNew             = false
    @_propsChanged      = {}
    @_domainEvents      = []
    @_entityClasses     = {}
    @_trackPropsChanged = true
    @_defineProperties()
    @_domainEvents = []

    @_root = new definition.root

    @id = @_generateUid()

    @_observerOpen()

    if typeof @_root.create == 'function'
      # TODO: Should be ok as long as aggregates arent async
      errorCallbackCalled = false
      errorCallback = (err) =>
        errorCallbackCalled = true
        callback err

      @_root.create props, errorCallback

      return if errorCallbackCalled
    else
      @applyProps props


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  _defineProperties: ->
    for key, value of @_props
      Object.defineProperty @, key,
        get: -> @_props[key]
        set: (newValue) -> @_set key, newValue


  _observerOpen: ->
    @_observer = new ObjectObserver @_root
    @_observer.open (added, removed, changed, getOldValueFn) =>
      Object.keys(added).forEach (property) =>
        @_set property, added[property]

      Object.keys(changed).forEach (property) =>
        @_set property, changed[property]


  _observerClose: ->
    @_observer.close()


  generateDomainEvent: (eventName, params={}) ->
    eventParams =
      name: eventName
      aggregate: @_getMetaData()

    changes = @_getChanges()
    if Object.keys(changes).length > 0
      eventParams.aggregate.changed = changes

    domainEvent = new DomainEvent eventParams
    @_domainEvents.push domainEvent


  _getMetaData: ->
    id: @id
    name: @_entityName


  _getChanges: ->
    @_observer.deliver()

    changes = {}
    if Object.keys(@_propsChanged).length > 0
      changes = @_propsChanged

    changes


  getDomainEvents: ->
    @_domainEvents


  applyChanges: (changes, params={}) ->
    @_observerClose()
    oldTrackPropsChanged = @_trackPropsChanged
    @_trackPropsChanged = false
    @_applyChanges changes
    @_trackPropsChanged = oldTrackPropsChanged

    @_observerOpen()


  _applyChanges: (propChanges) ->
    for propName, propValue of propChanges
      @_root[propName] = propValue
      @_set propName, propValue


  clearChanges: ->
    @_observerClose()
    @_propsChanged = {}
    # TODO: clear changes of nested entities
    @_observerOpen()


  applyProps: (props) ->
    @_root[key] = value for key, value of props


  _set: (key, value) ->
    @_props ?= {}
    @_propsChanged ?= {}

    if @_trackPropsChanged and key != 'id'
     @_propsChanged[key] = value

    @_props[key] = value


  _get: (key) ->
    @_props[key]


  toJSON: ->
    _.clone @_props


module.exports = Aggregate
