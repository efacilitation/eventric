_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteRepositoryService

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService) ->


  rpc: (payload, callback) ->

    @_remoteService.rpc payload, (err, responses) =>
      results = []
      for response in responses
        Class = @getClass response.aggregate.name
        if not Class
          err = new Error "Tried to built not registered Class #{response.aggregate.name} from RPC Response"
          return callback err, null

        instance = new Class
        instance.applyChanges response.aggregate.changed if response.aggregate.changed?

        results.push instance

      callback null, results


module.exports = RemoteRepositoryService