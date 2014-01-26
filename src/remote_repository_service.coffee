_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteRepositoryService

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService) ->


  rpc: (payload, callback) ->

    @_remoteService.rpc 'RemoteRepositoryService', payload, (err, responses) =>
      return callback err, null if err

      results = []
      for response in responses
        Class = @getClass response.aggregate?.name
        if not Class
          err = new Error "Tried to built not registered Class #{response.aggregate.name} from RPC Response"
          return callback err, null

        instance = new Class
        instance.applyChanges response.aggregate.changed if response.aggregate.changed?

        results.push instance

      callback null, results


  handle: (payload, callback) ->

    repository = @getClass payload.repository
    if not repository
      err = new Error "Tried to handle RPC with not registered repository #{payload.repository}"
      return callback err, null

    if payload.method not of repository
      err = new Error "RPC tried to execute not existing method #{payload.method} on repository #{payload.repository}"
      return callback err, null

    repository[payload.method] payload.params..., (err, results) ->
      snapshots = []
      snapshots.push result.getSnapshot() for result in results
      callback null, snapshots



module.exports = RemoteRepositoryService