describe 'aggregate', ->
  aggregate = null
  DomainEvent = null
  contextFake = null

  beforeEach ->
    class AggregateClass

    DomainEvent = (params) ->
      @sampleValue = params.sampleValue

    contextFake =
      name: 'ExampleContext'
      getDomainEventPayloadConstructor: ->

    Aggregate = require './'
    aggregate = new Aggregate contextFake, 'ExampleAggregate', AggregateClass
    aggregate.setId 'aggregate-1'


  describe '#setId', ->

    it 'should set the id of the aggregate', ->
      aggregate.setId 'aggregate-id'
      expect(aggregate.id).to.equal 'aggregate-id'


    it 'should set the id of the aggregate instance', ->
      aggregate.setId 'aggregate-id'
      expect(aggregate.instance.$id).to.equal 'aggregate-id'


  describe '#emitDomainEvent', ->

    it 'should throw an error given there is no domain event payload constructor defined on the context', ->
      expect(-> aggregate.emitDomainEvent 'DomainEventName').to.throw Error, /not defined/


    describe 'given a payload constructor is defined on the context', ->
      domainEvent = null

      beforeEach ->
        contextFake.getDomainEventPayloadConstructor = ->
          return DomainEvent
        aggregate.emitDomainEvent 'DomainEventName', sampleValue: 'sample-value'
        domainEvent = aggregate.getNewDomainEvents()[0]


      it 'should save a domain event with a domain event id', ->
        expect(domainEvent.id).to.be.a.number


      it 'should save a domain event with a name', ->
        expect(domainEvent.name).to.equal 'DomainEventName'


      it 'should save a domain event with an aggregate', ->
        expect(domainEvent.aggregate).to.be.an.object
        expect(domainEvent.aggregate.id).to.equal 'aggregate-1'
        expect(domainEvent.aggregate.name).to.equal 'ExampleAggregate'


      it 'should save a domain event with a context', ->
        expect(domainEvent.context).to.equal 'ExampleContext'


      it 'should save a domain event with a payload', ->
        expect(domainEvent.payload.sampleValue).to.equal 'sample-value'
