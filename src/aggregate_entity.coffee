_                         = require 'underscore'
eventric                  = require 'eventric'

MixinSetGet               = eventric 'MixinSetGet'
AggregateEntity           = eventric 'AggregateEntity'
AggregateEntityCollection = eventric 'AggregateEntityCollection'

class AggregateEntity

  _.extend @prototype, MixinSetGet::

  constructor: (@_props = {}) ->
    @_isNew             = false
    @_propsChanged      = {}
    @_domainEvents      = []
    @_entityClasses     = {}
    @_trackPropsChanged = true

  create: ->
    @id = @_generateUid()
    @_isNew = true

  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()

  getMetaData: ->
    id: @id
    name: @constructor.name

  getChanges: ->
    changes =
      props: @_changesOnProperties()

      # TODO one-to-one entity relation
      entities: {}

      # one-to-many entity relation
      collections: @_changesOnCollections()

    if @_changesAreNotEmpty changes
      changes

    else
      # return empty object if nothing changed
      {}

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
        if collectionChanges.length > 0
          changes[propkey] = collectionChanges
    changes

  _changesOnCollection: (collectionName, collection) ->
    changes = []
    for entity in collection.entities
      entityChanges = entity.getChanges()
      entityChanged = @_changesAreNotEmpty entityChanges
      if entityChanged || entity._isNew
        entity = entity.getMetaData()
        entity.changed = entityChanges if entityChanged
        changes.push entity
    changes

  _changesAreNotEmpty: (changes) ->
    for key, value of changes
      if Object.keys(value).length > 0
        return true

    return false

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
    @_set propName, propValue for propName, propValue of propChanges

  _applyChangesToCollections: (collectionChanges) ->
    for collectionName, collection of collectionChanges
      if @_get collectionName
        @_set collectionName, new AggregateEntityCollection
        @_applyChangesToCollection collectionName, collection

  _applyChangesToCollection: (collectionName, collection) ->
    for entity in collection
      entityInstance = @_get[collectionName]?.get entity.id
      if !entityInstance
        if EntityClass = @getEntityClass entity.name
          entityInstance = new EntityClass
        else
          # TODO this should trigger a warning somehow..
          entityInstance = new AggregateEntity

        entityInstance.id = entity.id
        # this will actually add a reference, so we can applyChanges afterwards safely
        @_get(collectionName).add entityInstance

      if entity.changed
        entityInstance.applyChanges entity.changed




  getEntityClass: (className) ->
    EntityClass = @_entityClasses[className] ? false

  registerEntityClass: (className, Class) ->
    @_entityClasses[className] = Class

module.exports = AggregateEntity