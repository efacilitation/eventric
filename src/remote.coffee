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
    commandArguments = arguments
    new Promise (resolve, reject) =>
      transportName = @get 'default transport'
      transport = @getTransport transportName
      transport.rpc
        transportName: transportName
        payload:
          contextName: @_contextName
          method: 'command'
          params: commandArguments
      .then (result) ->
        resolve result
      .catch (error) ->
        reject error


  query: ->
    queryArguments = arguments
    new Promise (resolve, reject) =>
      transportName = @get 'default transport'
      transport = @getTransport transportName
      transport.rpc
        transportName: transportName
        payload:
          contextName: @_contextName
          method: 'query'
          params: queryArguments
      .then (result) ->
        resolve result
      .catch (error) ->
        reject error


  addTransport: (transportName, Transport) ->
    @_transports[transportName] = new Transport


  getTransport: (transportName) ->
    @_transports[transportName]


module.exports = Remote
