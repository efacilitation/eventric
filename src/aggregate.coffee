eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
Clone           = eventric.require 'HelperClone'
DomainEvent     = eventric.require 'DomainEvent'
ObjectDiff      = eventric.require 'HelperObjectDiff'

class Aggregate

  constructor: (name, definition) ->
    @_name         = name
    @_domainEvents = []
    @_definition   = definition
    @_oldRoot      = {}

    if !@_definition
      @_root = {}
    else
      # TODO: check for valid definition
      @_root = new @_definition.root


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

    diff = ObjectDiff.getDifferences @_oldRoot, @_root
    eventParams.aggregate.diff = diff
    eventParams.aggregate.changed = ObjectDiff.applyDifferences {}, diff

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
    @_oldRoot = Clone @_root


  _applyDomainEvent: (domainEvent) ->
    if domainEvent.aggregate.diff
      ObjectDiff.applyDifferences @_root, domainEvent.aggregate.diff


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
