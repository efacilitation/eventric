_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteBoundedContext

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService) ->

  command: (boundedContextName, commandName, commandPayload) ->
    @rpc
      class: 'BoundedContext'
      method: 'command'
      params: [
        boundedContextName
        commandName
        commandPayload
      ]
      (err, data) -> callback null, data

  query: (boundedContextName, queryName, queryPayload) ->
    @rpc
      class: 'BoundedContext'
      method: 'query'
      params: [
        boundedContextName
        queryName
        queryPayload
      ]
      (err, data) -> callback null, data

  rpc: (payload, callback) ->
    @_remoteService.rpc 'RemoteBoundedContext', payload, (data) ->
      callback data

  handle: (payload, callback) ->
    boundedContext = @getClass payload.params[0]
    if not boundedContext
      err = new Error "Tried to handle RPC class with not registered boundedContext #{payload.params[0]}"
      return callback err, null

    if payload.method not of boundedContext
      err = new Error "RPC method #{payload.method} not found on Class #{payload.params[0]}"
      return callback err, null

    methodParams =
      name: payload.params[1]
      params: payload.params[2]
    boundedContext[payload.method] methodParams
    callback null, null



module.exports = RemoteBoundedContext