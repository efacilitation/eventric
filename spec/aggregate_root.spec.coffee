describe 'AggregateRoot', ->
  AggregateRoot = eventric 'AggregateRoot'
  enderAggregate = null
  beforeEach ->
    class EnderAggregate extends AggregateRoot

    enderAggregate = new EnderAggregate

  describe '#create', ->

    it 'should generate an id', ->
      enderAggregate.create()
      expect(enderAggregate.id).to.be.string

  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      enderAggregate._set 'name', 'John'
      eventName = 'somethingHappend'

    it 'should create an event including changes', ->
      enderAggregate.generateDomainEvent eventName

      expect(enderAggregate.getDomainEvents()[0].name).to.equal eventName
      expect(enderAggregate.getDomainEvents()[0].aggregate.changed.props.name).to.equal enderAggregate._get 'name'

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


  describe '#getSnapshot', ->

    it 'should return the current state as special "_snapshot"-DomainEvent', ->
      enderAggregate.id = 42
      enderAggregate._set 'name', 'John'

      expect(enderAggregate.getSnapshot()).to.eql
        name: '_snapshot'
        aggregate:
          id: 42
          name: 'EnderAggregate'
          changed:
            props:
              name: 'John'
            entities: {}
            collections: {}