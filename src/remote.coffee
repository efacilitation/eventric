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


  subscribeToDomainEvent: (eventName, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    fullEventName = "#{@_contextName}/#{eventName}"
    client.subscribe fullEventName, handlerFn


  unsubscribeFromDomainEvent: (eventName, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    fullEventName = "#{@_contextName}/#{eventName}"
    client.unsubscribe fullEventName, handlerFn


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
