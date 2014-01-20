eventric = require 'eventric'

AggregateEntity           = eventric 'AggregateEntity'
AggregateEntityCollection = eventric 'AggregateEntityCollection'

class MixinSnapshot

  getSnapshot: ->
    snapshot =
      name: '_snapshot'
      aggregate: @getMetaData()

    snapshot.aggregate.changed =
      props: @_toSnapshotOnProps()
      entities: {} # TODO
      collections: @_toSnapshotOnCollections()

    snapshot

  _toSnapshotOnProps: ->
    snapshot = {}
    snapshot[propKey] = propVal for propKey, propVal of @_props when propVal not instanceof AggregateEntityCollection and propVal not instanceof AggregateEntity
    snapshot

  _toSnapshotOnCollections: ->
    snapshot = {}
    for propKey, propValue of @_props
      if propValue instanceof AggregateEntityCollection
        snapshot[propKey] = []
        for entity in propValue.entities
          snapshot[propKey].push entity.tosnapshot()

    snapshot

module.exports = MixinSnapshot