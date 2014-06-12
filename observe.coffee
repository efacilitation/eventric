someObj = {}

Object.observe someObj, (added, changed, removed) ->
  console.log 'added', added[0]
  console.log 'changed', changed
  console.log 'removed', removed

someObj.nestedObject = {foo: 'bar'}

Object.observe someObj.nestedObject, ->
  # changetracking

someObj.someArray = ['moo']

Array.observe someObj.someArray, ->
  console.log 'array changed', arguments[0][0]

setTimeout ->
  console.log 'changing object'
  #someObj.nestedObject.foo = 'somethingelse'
  someObj.someArray.push 'somethingelse'
  someObj.someArray[13] = 'wat'
, 1000


setTimeout ->
  someObj.someArray[23] = 'illuminati'
  delete someObj.someArray[23]
  someObj.someArray['3s'] = '3'
, 1002

setTimeout ->
  console.log 'array data'
  console.log Object.keys(someObj.someArray)
  console.log Object.keys(someObj.someArray).map((x) -> someObj.someArray[x])
  console.log someObj.someArray.length
, 1003

# undefined in mongo db?
# type (value, reference/objects, arrays), operation (assignment, delete), value, optional property




{

  changed:

  deleted:

  arrays:

  changed:
    property1: 'value'

    property2: undefined

    nestedObject:
      nestedProperty: 'value'

    roomOwners[3].name = 'Hans'

    roomOwners:
      3:
        name: 'Hans'

  deleted:


  types:
    property1


## Super Alex Sample!

a =
  foo: 'bar'

b =
  foo: 'bar'
  foo2: 'bar2'

differences = getDifference a, b
c = {}
applyDifferences c, differences

expect(c.hullebulle).to.be 'waat'
expect(c.foo).to.not.exist

applyDifferences a, differences
expect(a).to.be.deep.equal b




##

{
  changed:
    owners:
      3:
        name: 'Hans'

  deleted:
    owners:
      3: null
}

class Room
  changeOwnerName: (ownerId, name) ->
    @owners[ownerId].changeName name


class RoomOwner
  changeName: (name) ->
    @name = name

# '1234', 'Hans'

# RoomOwner:changeName
# changed
# name:

collaboration.addDomaRinEvRntHandler 'Room:changeOwnerName', (domainEvent) ->
  changes = domainEvent.getAggregateChanges()
  [null, null, {name: 'Hans'}]
  changes.roomOwners.filter(!null)[0].name


  changed:
    owners: [null, null, name: 'Hans']


  for ownerId, owner in changes.owners.map((owner) -> owner not null)


  getAggregateChanges '$.owners.*', (index, owner, type) -> ui.owners[index].name = name
}

accessIdentity.addDomainEventHandler 'Account:create', (domainEvent) ->
  accountId = domainEvent.aggregate.id
  changes = domainEvent.getAggregateChanges()
  email = changes.email