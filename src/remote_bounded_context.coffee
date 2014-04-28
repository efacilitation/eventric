_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteBoundedContext

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService, @_boundedContextName) ->

  command: (commandName, commandPayload) ->
    @rpc
      class: 'BoundedContext'
      method: 'command'
      params: [
        @_boundedContextName
        commandName
        commandPayload
      ]
      (err, data) -> callback null, data

  query: (queryName, queryPayload) ->
    @rpc
      class: 'BoundedContext'
      method: 'query'
      params: [
        @_boundedContextName
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

    boundedContext[payload.method] payload.params[1], payload.params[2], (err, result) ->
      return callback err, null if err
      callback null, result



module.exports = RemoteBoundedContext