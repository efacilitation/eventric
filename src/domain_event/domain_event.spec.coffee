describe 'DomainEvent', ->

  DomainEvent = require './domain_event'

  describe '#constructor', ->

    it 'should set all necessary properties', ->
      sandbox.stub(Date::, 'getTime').returns 1
      payload =
        someProperty: 42
      aggregate =
        aggregate:
          id: 42
      domainEvent = new DomainEvent
        name: 'Name'
        payload: payload
        aggregate: aggregate
        context: 'ExampleContext'

      expect(domainEvent.name).to.equal 'Name'
      expect(domainEvent.payload).to.equal payload
      expect(domainEvent.aggregate).to.equal aggregate
      expect(domainEvent.context).to.equal 'ExampleContext'
      expect(domainEvent.timestamp).to.equal 1
