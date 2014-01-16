Eventric

--

thoughts on data inside the aggregate:

only use primitives (string, number, boolean)
if you need objects or arrays, use entities or entitycollections!

this has multiple reasons, but foremost its because its really difficult to automatically include changes into the domainevent
maybe let _set check if you want to set object/array and then just tell you: sorry, not possible?


see also:
http://stackoverflow.com/questions/11661380/does-backbone-models-this-get-copy-an-entire-array-or-point-to-the-same-array

--

thoughts on repository:

Es ist notwendig, dass man alle Aggregate und ReadAggregate beim Repository registriert,
damit es dem Repository möglich ist basierend auf dem Namen die entsprechenden Instanzen
zu bauen!

    aggregateRepository.registerClass 'Passenger', Passenger

readAggregateRepository.registerClass 'ReadPassenger', ReadPassenger

aggregateRepository.findById 'Passenger', 1, ->

readAggregateRepository.find 'ReadPassenger', query, ->

Im Falle von spezialisierten ReadAggregateRepositories ist das Verhalten dann konsistent,
denn man kann bei diesen intern entsprechend im constructor die passende Klasse registrieren.


class ReadPassengerRepository extends Repository

  constructor: ->
    super
    @registerClass 'ReadPassenger', require('some-module')('ReadPassenger')

  findAllDelayedBy10MinutesAndMore: ->
    @_eventStore.find query, (err, result) ->
      ...


---


Alternative wäre, dass sich Read/Aggregate selbst bauen indem man ihnen einen EventStore/Repository
zur Verfügung stellt. Allerdings sollen Aggregate durch die CommandSchicht weggeschachtelt
werden. Damit wäre diese Anforderung verletzt

aggregate = new Aggregate eventStore

---

thoughts on event-structure:

# event data
name: 'create'
timestamp: '201401111747'

# aggregate data
aggregate:
  id: 1
  name: 'Train'
  changed:

    # properties
    props:
      trainName: 'ICE 3272'

    # one-to-one entity relation
    entities:
      lokfuehrer:
        id: _123
        name: 'Lokfuehrer'
        changed:
          props:
            name: 'Hans'

    # one-to-many entity relation
    collections:
      passengers: [
        id: _1
        name: 'Passenger'
        changed:
          props:
            seat: 'XYZ'
      ]


---

