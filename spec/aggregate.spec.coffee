describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  AggregateEntity = eventric.require 'AggregateEntity'
  enderAggregate  = null
  beforeEach ->
    class EnderAggregateRootStub
    aggregateDefinition =
      root: EnderAggregateRootStub
    enderAggregate = new Aggregate 'EnderAggregate', aggregateDefinition


  describe.skip 'given a create method is present on the aggregate root', ->
    it 'should call the create method on the aggregate with the initial parameters', (done) ->
      aggregateService.create 'ExampleAggregate', initialProps, ->
        expect(exampleAggregateRoot.create).to.have.been.calledWith initialProps
        done()


  describe.skip 'given no create method is present on the aggregate root', ->
    it 'should apply the initial paramters directly on the aggregate', (done) ->
      delete exampleAggregateRoot.create
      aggregateService.create 'ExampleAggregate', initialProps, (err) ->
        expect(Aggregate::applyProps).to.have.been.calledWith initialProps
        done()


  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      enderAggregate.root.name = 'John'
      eventName = 'somethingHappend'


    it 'should create a DomainEvent including changes', ->
      console.log enderAggregate
      enderAggregate.generateDomainEvent eventName
      expect(enderAggregate.getDomainEvents()[0].getName()).to.equal eventName
      expect(enderAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        name: enderAggregate.root.name


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
