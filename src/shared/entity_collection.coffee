_ = require 'underscore'

Function::prop = (propName, desc = {}) ->
  Object.defineProperty @::, propName, _.defaults desc,
    get: ->
      @['_' + propName]
    set: (val) ->
      @['_' + propName] = val



class EntityCollection

  constructor: (options = {}) ->
    @_entities = []
    @add options.entities if options.entities
    @

  add: (entity) ->
    if entity instanceof Array
      @_entities = @_entities.concat entity
    else
      @_entities.push entity
    @

  remove: (entity) ->
    for currentEntity, idx in @_entities
      if currentEntity is entity
        @_entities = @_entities.slice idx + 1
        break
    @

  get: (id) ->
    for entity in @_entities
      if id is entity.id
        return entity

  @prop 'entities',
    set: -> throw "Don't set entities directly"
    get: -> @_entities

  @prop 'length',
    set: -> throw "Don't set length directly"
    get: -> @_entities.length


module.exports = EntityCollection