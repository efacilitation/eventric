lastMicrosecondTimestamp = null
counter = 0

module.exports =
  generateId: ->
    microsecondTimestamp = Date.now() * 1000

    if lastMicrosecondTimestamp is microsecondTimestamp
      counter++
      domainEventId = microsecondTimestamp + counter
    else
      counter = 0
      domainEventId = microsecondTimestamp

    lastMicrosecondTimestamp = microsecondTimestamp

    return domainEventId
