_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'


class RemoteService

  # TODO "register*Class*" is the wrong terminology here, since its actually an instance
  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_adapter) ->

  rpc: (payload, callback) ->
    @_adapter.rpc payload, ->
      callback null

  handle: (payload, callback) ->
    instance = @getClass payload.class
    instance[payload.method] payload.params..., (err, status) ->
      return callback err, null if err
      callback null, status


module.exports = RemoteService