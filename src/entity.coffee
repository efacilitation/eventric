_ = require 'underscore'
EntityCollection = require './entity_collection'

class Entity

  constructor: (@_props = {}) ->
    @_trackPropsChanged = true
    @_propsChanged = {}
    @_domainEvents = []

  _data: ->
    id: @id
    entity: @_entityName

  _changes: ->
    props: @_changesOnProperties()
    collections: @_changesOnCollections()

  _changesOnProperties: ->
    changes = {}
    if Object.keys(@_propsChanged).length > 0
      changes = @_propsChanged
    changes

  _changesOnCollections: ->
    changes = {}
    for propkey, propvalue of @_props
      if propvalue instanceof EntityCollection
        collectionChanges = @_changesOnCollection propkey, propvalue
        if Object.keys(collectionChanges).length > 0
          changes[propkey] = collectionChanges
    changes

  _changesOnCollection: (collectionName, collection) ->
    changes = []
    for entity in collection.entities
      entityChanges = entity._changes()
      if Object.keys(entityChanges).length > 0
        entityChanges.data = entity._data()
        changes.push entityChanges
    changes

  _clearChanges: ->
    @_propsChanged = {}

    for propKey, propVal of @_props when propVal instanceof EntityCollection
      @_clearCollectionChanges propVal

  _clearCollectionChanges: (collection) ->
    for entity in collection.entities
      entity._clearChanges()

  _applyChanges: (changes, params={}) ->
    @_applyChangesToProps changes.props
    @_applyChangesToCollections changes.collections

  _applyChangesToProps: (propChanges) ->
    @[propName] = propValue for propName, propValue of propChanges

  _applyChangesToCollections: (collectionChanges) ->
    for collectionName, collection of collectionChanges
      @_applyChangesToCollection collectionName, collection

  _applyChangesToCollection: (collectionName, collection) ->
    for subChanges in collection
      entity = @[collectionName].get subChanges.data.id
      entity._applyChanges subChanges

  _shouldTrackChangePropertiesFor: (propName, val) ->
    @_trackPropsChanged and @_props[propName] != val and val not instanceof EntityCollection

  # TODO: Refactor, push to a mixin (like Backbone Events). Use hooks to execute custom behaviour like "@onSet?()".
  # We need the props at the query entities too.
  @prop = (propName, desc) ->
    Object.defineProperty @::, propName, _.defaults desc || {},
      get: -> @_props[propName]
      set: (val) ->
        @_props = {} unless @_props

        if @_shouldTrackChangePropertiesFor propName, val
          @_propsChanged[propName] = val

        @_props[propName] = val

  @props = (propNames...) ->  @prop(propName) for propName in propNames

module.exports = Entity