eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
Clone           = eventric.require 'HelperClone'
DomainEvent     = eventric.require 'DomainEvent'

class Aggregate

  constructor: (name, definition) ->
    @_name         = name
    @_propsChanged = {}
    @_domainEvents = []
    @_definition   = definition
    @_root         = new @_definition.root


  create: (props) ->
    @id = @_generateUid()

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


  generateDomainEvent: (eventName, params={}) ->
    eventParams =
      name: eventName
      aggregate:
        id: @id
        name: @_name

    if Object.keys(@_propsChanged).length > 0
      eventParams.aggregate.changed = @_propsChanged

    entityMap = @_getEntityMap()
    if Object.keys(entityMap).length > 0
      eventParams.aggregate.entityMap = entityMap

    domainEvent = new DomainEvent eventParams
    @_domainEvents.push domainEvent


  _getEntityMap: ->
    entityMap = {}

    for entityName, entityClass of @_definition.entities
      entityMap[entityName] = []
      @_getPathsToEntityClass entityClass, @_root, entityMap[entityName]

    entityMap


  _getPathsToEntityClass: (entityClass, obj, map, path = []) ->
    if obj instanceof entityClass
      map.push path

    if Object.keys(obj).length == 0
      path = []

    _.each obj, (val, key) =>
      eachPath = Clone path
      eachPath.push key
      if _.isObject val
        @_getPathsToEntityClass entityClass, val, map, eachPath

    path


  getDomainEvents: ->
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    if domainEvent.aggregate.changed
      for propName, propValue of domainEvent.aggregate.changed
        @_root[propName] = propValue


  toJSON: ->
    Clone @_root


  command: (command, errorCallback) ->
    if command.name not of @_root
      err = new Error "Given commandName '#{command.name}' not found as method in the #{@_name} Aggregate Root"
      errorCallback err
      return

    # make sure we have a params array
    command.params = [] if !command.params
    if not (command.params instanceof Array)
      command.params = [command.params]

    @_root[command.name] command.params..., errorCallback


module.exports = Aggregate
