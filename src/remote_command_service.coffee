class RemoteCommandService

  constructor: (@_remoteService) ->

  createAggregate: (aggregateName) ->
    @_remoteService.rpc
      class: 'CommandService'
      method: 'createAggregate'
      params: [
        aggregateName
      ]

module.exports = RemoteCommandService