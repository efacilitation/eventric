class Remote

  constructor: (@_contextName) ->
    @_params = {}
    @_clients = {}
    @addClient 'inmemory', (require './remote_inmemory').client
    @set 'default client', 'inmemory'


  set: (key, value) ->
    @_params[key] = value


  get: (key) ->
    @_params[key]


  command: ->
    @_rpc 'command', arguments


  query: ->
    @_rpc 'query', arguments


  subscribeToDomainEvent: ->
    @_rpc 'addDomainEventHandler', arguments


  _rpc: (method, params) ->
    new Promise (resolve, reject) =>
      clientName = @get 'default client'
      client = @getClient clientName
      client.rpc
        clientName: clientName
        payload:
          contextName: @_contextName
          method: method
          params: params
      .then (result) ->
        resolve result
      .catch (error) ->
        reject error


  addClient: (clientName, Client) ->
    @_clients[clientName] = new Client


  getClient: (clientName) ->
    @_clients[clientName]


module.exports = Remote
