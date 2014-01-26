class RemoteService

  constructor: (@_adapter) ->
    @_serviceHandlers = {}


  rpc: (serviceName, payload, callback) ->
    rpc =
      service: serviceName
      payload: payload

    @_adapter.rpc rpc, (data) ->
      callback null, data


  handle: (rpc, callback) ->

    service = @getServiceHandler rpc.service
    if not service
      err = new Error "Tried to handle RPC call with not registered service #{rpc.service}"
      return callback err, null

    if 'handle' not of service
      err = new Error "Service #{rpc.service} has no handle method"
      return callback err, null

    service.handle rpc.payload, callback


  registerServiceHandler: (serviceName, service) ->
    @_serviceHandlers[serviceName] = service


  getServiceHandler: (serviceName) ->
    return false unless serviceName of @_serviceHandlers
    @_serviceHandlers[serviceName]


module.exports = RemoteService