class Remote

  constructor: (@_contextName) ->
    @_params = {}
    @_transports = {}
    @addTransport 'inmemory', (require './remote_inmemory').transport
    @set 'default transport', 'inmemory'


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
      transportName = @get 'default transport'
      transport = @getTransport transportName
      transport.rpc
        transportName: transportName
        payload:
          contextName: @_contextName
          method: method
          params: params
      .then (result) ->
        resolve result
      .catch (error) ->
        reject error


  addTransport: (transportName, Transport) ->
    @_transports[transportName] = new Transport


  getTransport: (transportName) ->
    @_transports[transportName]


module.exports = Remote
