class Remote

  constructor: (@_contextName) ->


  command: ->
    commandArguments = arguments
    new Promise (resolve, reject) =>
      context = eventric.getContext @_contextName
      context.command commandArguments...
      .then ->
        resolve()

module.exports = Remote
