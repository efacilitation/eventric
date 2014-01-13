_                         = require 'underscore'
eventric                  = require 'eventric'

AggregateEntity           = eventric 'AggregateEntity'
AggregateEntityCollection = eventric 'AggregateEntityCollection'

class AggregateEntity

  constructor: (@_props = {}) ->
    @_trackPropsChanged = true
    @_propsChanged = {}
    @_domainEvents = []
    @_entityClasses = {}

  getMetaData: ->
    id: @id
    name: @constructor.name

  getChanges: ->
    props: @_changesOnProperties()

    # TODO one-to-one entity relation
    entities: {}

    # one-to-many entity relation
    collections: @_changesOnCollections()

  _changesOnProperties: ->
    changes = {}
    if Object.keys(@_propsChanged).length > 0
      changes = @_propsChanged
    changes

  _changesOnCollections: ->
    changes = {}
    for propkey, propvalue of @_props
      if propvalue instanceof AggregateEntityCollection
        collectionChanges = @_changesOnCollection propkey, propvalue
        if Object.keys(collectionChanges).length > 0
          changes[propkey] = collectionChanges
    changes

  _changesOnCollection: (collectionName, collection) ->
    changes = []
    for entity in collection.entities
      entityChanges = entity.getChanges()
      if Object.keys(entityChanges).length > 0
        entity = entity.getMetaData()
        entity.changed = entityChanges
        changes.push entity
    changes

  clearChanges: ->
    @_propsChanged = {}

    for propKey, propVal of @_props when propVal instanceof AggregateEntityCollection
      @_clearCollectionChanges propVal

  _clearCollectionChanges: (collection) ->
    entity.clearChanges() for entity in collection.entities

  applyChanges: (changes, params={}) ->
    oldTrackPropsChanged = @_trackPropsChanged
    @_trackPropsChanged = false
    @_applyChangesToProps changes.props
    @_applyChangesToCollections changes.collections
    @_trackPropsChanged = oldTrackPropsChanged

  _applyChangesToProps: (propChanges) ->
    @[propName] = propValue for propName, propValue of propChanges

  _applyChangesToCollections: (collectionChanges) ->
    for collectionName, collection of collectionChanges
      @[collectionName] = new AggregateEntityCollection
      @_applyChangesToCollection collectionName, collection

  _applyChangesToCollection: (collectionName, collection) ->
    for entity in collection
      if EntityClass = @getEntityClass entity.name
        entityInstance = new EntityClass
      else
        # TODO this should trigger a warning somehow..
        entityInstance = new AggregateEntity

      entityInstance.id = entity.id
      entityInstance.applyChanges entity.changed
      @[collectionName].add entityInstance

  _shouldTrackChangePropertiesFor: (propName, val) ->
    @_trackPropsChanged and @_props[propName] != val and val not instanceof AggregateEntityCollection

  toJSON: ->
    json = @getMetaData()
    json.props = @_toJSONonProps()
    json.entities = {} # TODO
    json.collections = @_toJSONonCollections()
    json

  _toJSONonProps: ->
    json = {}
    json[propKey] = propVal for propKey, propVal of @_props when propVal not instanceof AggregateEntityCollection and propVal not instanceof AggregateEntity
    json

  _toJSONonCollections: ->
    json = {}
    for propKey, propValue of @_props
      if propValue instanceof AggregateEntityCollection
        json[propKey] = []
        for entity in propValue.entities
          json[propKey].push entity.toJSON()

    json

  getEntityClass: (className) ->
    EntityClass = @_entityClasses[className] ? false

  registerEntityClass: (className, Class) ->
    @_entityClasses[className] = Class

  # TODO: Replace with _set/_get, we dont want to define a prop-schema
  @prop = (propName, desc) ->
    Object.defineProperty @::, propName, _.defaults desc || {},
      get: -> @_props[propName]
      set: (val) ->
        @_props = {} unless @_props

        if @_shouldTrackChangePropertiesFor propName, val
          @_propsChanged[propName] = val

        @_props[propName] = val

  @props = (propNames...) ->  @prop(propName) for propName in propNames

module.exports = AggregateEntity