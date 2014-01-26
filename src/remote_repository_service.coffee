_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteRepositoryService

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService) ->


  rpc: (payload, callback) ->
    RepositoryClass = @getClass payload.class
    if not RepositoryClass
      err = new Error "Tried to RemoteCall not registered Class #{payload.class}"
      return callback err, null

    repository = new RepositoryClass

    @_remoteService.rpc payload, (err) ->
      return callback err, null if err
      callback null, repository


module.exports = RemoteRepositoryService