_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'


class ReadMixRepository

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_eventStore) ->

  load: (readMixName, callback) ->
    # the query will someday include the GUID / userId or something like that
    ReadMixClass = @getClass readMixName

    if not ReadMixClass
      err = new Error "Tried to load not registered ReadMix '#{readMixName}'"
      callback err, null

    else
      readMix = new ReadMixClass

      # TODO: refactor the uglyness
      @_eventStore.findByAggregateName readMix.applyDomainEventsFromAggregate, (err, events) =>

        if err
          callback err, null

        else
          readMix.loadFromEvents events

          callback null, readMix


module.exports = ReadMixRepository