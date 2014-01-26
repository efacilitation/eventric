class RemoteCommandService

  constructor: (@_remoteService) ->

  createAggregate: (aggregateName, callback) ->
    @_remoteService.rpc
      class: 'CommandService'
      method: 'createAggregate'
      params: [
        aggregateName
      ]
      -> callback null

  commandAggregate: (aggregateName, aggregateId, commandName, commandParams, callback) ->
    @_remoteService.rpc
      class: 'CommandService'
      method: 'commandAggregate'
      params: [
        aggregateName,
        aggregateId,
        commandName,
        commandParams
      ]
      -> callback null

module.exports = RemoteCommandService