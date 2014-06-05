describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  AggregateEntity = eventric.require 'AggregateEntity'
  enderAggregate  = null
  beforeEach ->
    enderAggregate = new Aggregate 'EnderAggregate'


  describe '#initialize', ->
    it 'should generate an id', ->
      enderAggregate.initialize()
      expect(enderAggregate.id).to.be.string


  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      enderAggregate.name = 'John'
      eventName = 'somethingHappend'


    it 'should create a DomainEvent including changes', ->
      enderAggregate.generateDomainEvent eventName
      expect(enderAggregate.getDomainEvents()[0].getName()).to.equal eventName
      expect(enderAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        name: enderAggregate.name


    describe 'given param includeAggregateChanges is set to false', ->
      it 'then it should NOT include and clear the  changes', ->
        enderAggregate.generateDomainEvent eventName, {includeAggregateChanges: false}
        expect(enderAggregate.getDomainEvents()[0].name).to.equal eventName
        expect(enderAggregate.getDomainEvents()[0].aggregate.changed).to.equal undefined


  describe '#getDomainEvents', ->
    it 'should return the accumulated domainEvents', ->
      enderAggregate._domainEvents = ['someEvent']
      domainEvents = enderAggregate.getDomainEvents()
      expect(domainEvents.length).to.equal 1
