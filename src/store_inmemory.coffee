module.exports =

  _events: {}
  _projections: {}

  save: (collectionName, doc, callback) ->
    @_events[collectionName] ?= []
    @_events[collectionName].push doc
    callback null, doc


  find: ([collectionName, query, projection]..., callback) ->
    events = []
    @_events[collectionName] ?= []

    if query['aggregate.id']
      aggregateId = query['aggregate.id']

      events = @_events[collectionName].filter (event) ->
        event.aggregate.id == aggregateId

    else
      events = @_events[collectionName]

    callback null, events


  getProjectionStore: (projectionName, callback) ->
    @_projections[projectionName] ?= {}
    callback null, @_projections[projectionName]


  clearProjectionStore: (projectionName, callback) ->
    delete @_projections[projectionName]
    callback null, null


  getStoreName: ->
    'inmemory'
