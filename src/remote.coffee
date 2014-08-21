class Remote

  constructor: (@_contextName) ->
    @_params = {}
    @_clients = {}
    @addClient 'inmemory', (require './remote_inmemory').client
    @set 'default client', 'inmemory'


  set: (key, value) ->
    @_params[key] = value
    @


  get: (key) ->
    @_params[key]


  command: ->
    @_rpc 'command', arguments


  query: ->
    @_rpc 'query', arguments


  subscribeToDomainEvent: ([domainEventName]..., handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    if domainEventName
      client.subscribe @_contextName, domainEventName, handlerFn
    else
      client.subscribe @_contextName, handlerFn


  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, aggregateId, handlerFn


  unsubscribeFromDomainEvent: ([domainEventName]..., handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    if domainEventName
      client.unsubscribe @_contextName, domainEventName, handlerFn
    else
      client.unsubscribe @_contextName, handlerFn


  unsubscribeFromDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.unsubscribe @_contextName, domainEventName, aggregateId, handlerFn


  _rpc: (method, params) ->
    new Promise (resolve, reject) =>
      clientName = @get 'default client'
      client = @getClient clientName
      client.rpc
        contextName: @_contextName
        method: method
        params: Array.prototype.slice.call params
      , (err, result) ->
        if err
          reject err
        else
          resolve result


  addClient: (clientName, client) ->
    @_clients[clientName] = client
    @


  getClient: (clientName) ->
    @_clients[clientName]


module.exports = Remote
