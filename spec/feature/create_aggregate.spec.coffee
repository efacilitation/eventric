describe 'Create new Aggregate Scenario', ->
  CommandService          = eventric.require 'CommandService'
  DomainEventService      = eventric.require 'DomainEventService'
  AggregateRoot           = eventric.require 'AggregateRoot'
  AggregateRepository     = eventric.require 'AggregateRepository'

  describe 'given we want to instantiate a new Aggregate', ->

    describe 'when we tell the CommandService to create an Aggregate', ->

      it 'then the DomainEventService should have triggered a "create" DomainEvent', (done) ->
        # so we have an aggregate defined
        class EnderAggregate extends AggregateRoot

        # create the EventStoreStub
        class EventStore
          find: ->
          save: ->
        eventStore = sinon.createStubInstance EventStore
        # simulate successful saving
        eventStore.save.yields null
        # create the DomainEventService
        domainEventService = new DomainEventService eventStore

        # stub DomainEventService.trigger
        DomainEventServiceTriggerSpy = sandbox.spy domainEventService, 'trigger'

        # create the AggregateRepositoryStub
        aggregateRepository = sinon.createStubInstance AggregateRepository
        # simulate "register Class 'EnderAggregate', EnderAggregate"
        aggregateRepository.getAggregateObj.returns EnderAggregate
        # simulate "nothing found"
        aggregateRepository.findById.yields null, null

        # register the aggregate class in the repository
        aggregateRepository.registerAggregateObj 'EnderAggregate', EnderAggregate

        # create the CommandService
        commandService = new CommandService domainEventService, aggregateRepository

        # now we tell the commandservice to create the aggregate for us
        commandService.createAggregate 'EnderAggregate', (err, aggrageId) ->

          expect(DomainEventServiceTriggerSpy.calledWith 'DomainEvent', sinon.match.has 'name', 'create').to.be.true
          done()