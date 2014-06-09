eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
DomainEvent     = eventric.require 'DomainEvent'

class Aggregate

  constructor: (name, definition, props) ->
    @_entityName        = name
    @_props             = {}
    @_propsChanged      = {}
    @_domainEvents      = []
    @_trackPropsChanged = true

    @id = @_generateUid()

    @_createRoot definition.root, props

    if definition.entities
      @_entitiesDefinition = definition.entities


  _createRoot: (root, props) ->
    @_root = new root
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
      @_root[key] = value for key, value of props


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


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

    entityMap = @_getEntityMap()
    if Object.keys(entityMap).length > 0
      eventParams.aggregate.entityMap = entityMap

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


  _getEntityMap: ->
    entityMap = {}

    for entityName, entityClass of @_entitiesDefinition
      entityMap[entityName] = []
      @_getPathsToEntityClass entityClass, @_root, entityMap[entityName]

    entityMap


  _getPathsToEntityClass: (entityClass, obj, map, path = []) ->
    if obj instanceof entityClass
      map.push path

    if Object.keys(obj).length == 0
      path = []

    _.each obj, (val, key) =>
      eachPath = _.clone path
      eachPath.push key
      if _.isObject val
        @_getPathsToEntityClass entityClass, val, map, eachPath

    path


  getDomainEvents: ->
    @_domainEvents


  applyChanges: (changes, params={}) ->
    @_observerClose()
    oldTrackPropsChanged = @_trackPropsChanged
    @_trackPropsChanged = false
    @_defineProperties changes
    @_applyChanges changes
    @_trackPropsChanged = oldTrackPropsChanged

    @_observerOpen()


  _defineProperties: (props) ->
    for key, value of props
      Object.defineProperty @_root, key,
        get: => @_props[key]
        set: (newValue) => @_set key, newValue


  _applyChanges: (propChanges) ->
    for propName, propValue of propChanges
      @_root[propName] = propValue
      @_set propName, propValue


  clearChanges: ->
    @_observerClose()
    @_propsChanged = {}
    # TODO: clear changes of nested entities
    @_observerOpen()


  _set: (key, value) ->
    if @_trackPropsChanged and key != 'id'
     @_propsChanged[key] = value

    @_props[key] = value


  _get: (key) ->
    @_props[key]


  toJSON: ->
    _.clone @_props


  command: (command, errorCallback) ->
    if command.name not of @_root
      err = new Error "Given commandName '#{command.name}' not found as method in the #{@_entityName} Aggregate Root"
      errorCallback err
      return

    # make sure we have a params array
    command.params = [] if !command.params
    if not (command.params instanceof Array)
      command.params = [command.params]

    @_root[command.name] command.params..., errorCallback


module.exports = Aggregate
