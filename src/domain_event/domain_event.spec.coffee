describe 'DomainEvent', ->

  DomainEvent = require './domain_event'

  createDomainEvent = (payload = {}, aggregate = {}) ->
    return new DomainEvent
      name: 'Name'
      payload: payload
      aggregate: aggregate
      context: 'ExampleContext'


  describe '#constructor', ->

    it 'should set all necessary properties', ->
      sandbox.stub(Date::, 'getTime').returns 1
      payloadObject = {someProperty: 42}
      aggregateObject = {aggregate: id: 42}
      domainEvent = createDomainEvent payloadObject, aggregateObject
      expect(domainEvent.name).to.equal 'Name'
      expect(domainEvent.payload).to.equal payloadObject
      expect(domainEvent.aggregate).to.equal aggregateObject
      expect(domainEvent.context).to.equal 'ExampleContext'
      expect(domainEvent.timestamp).to.equal 1


    it 'should not have an id when created', ->
      domainEvent = createDomainEvent()
      expect(domainEvent.id).to.be.undefined
