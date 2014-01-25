class RemoteCommandService

  constructor: (@_remoteService) ->

  createAggregate: (aggregateName) ->
    @_remoteService.rpc
      class: 'CommandService'
      method: 'createAggregate'
      params: [
        aggregateName
      ]

  commandAggregate: (aggregateName, aggregateId, commandName, commandParams) ->
    @_remoteService.rpc
      class: 'CommandService'
      method: 'commandAggregate'
      params: [
        aggregateName,
        aggregateId,
        commandName,
        commandParams
      ]

module.exports = RemoteCommandService