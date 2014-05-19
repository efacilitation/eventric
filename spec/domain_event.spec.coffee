describe 'DomainEvent', ->
  domainEvent = null

  beforeEach ->
    DomainEvent = eventric 'DomainEvent'
    domainEvent = new DomainEvent
      aggregate:
        changed:
          props:
            name: 'John'


  describe '#getChangedAggregateProps', ->
    it 'should return the changed aggregate properties', ->
      expect(domainEvent.getChangedAggregateProps()).to.deep.equal
        name: 'John'


  describe '#getTimestamp', ->
    it 'should return a timestamp', ->
      expect(domainEvent.getTimestamp()).to.be.an 'number'
