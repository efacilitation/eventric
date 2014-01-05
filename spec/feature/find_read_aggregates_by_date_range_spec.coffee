describe 'Find ReadAggregates By Date Range Scenario', ->

  expect   = require 'expect'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  ReadAggregateRepository = eventric 'ReadAggregateRepository'

  describe 'given we want to get all ReadExampleAggregates between two dates', ->

    describe 'when we ask the ReadExampleRepository to find the matching ReadAggregates', ->

      it 'then it should return the corresponding list of ReadExampleAggregates', ->
        # Example Classes
        class ReadExample extends ReadAggregateRoot

        class ReadExampleRepository extends ReadAggregateRepository

          findByDateRange: (start, end) ->
            # criteria not actually used here, just to show how it could look like
            exampleCriteria =
              aggregateName: 'ReadExample'
              eventName: 'create'
              eventTimestamp:
                $gte: start
                $lt: end

            # find the aggregateIds matching the criteria
            aggregateIds = @findIds exampleCriteria

            # find the actual ReadAggregates by id
            readAggregates = @findByIds aggregateIds

        class ExampleAdapter
          find: ->
          _findDomainEventsByAggregateId: ->

        # create a stub instance of the ExampleAdapter
        exampleAdapterStub = sinon.createStubInstance ExampleAdapter

        # stub ExampleAdapter.find to return an example id only
        exampleAdapterStub.find.returns [
          {'id': 1}
        ]

        # stub ExampleAdapter._findDomainEventsByAggregateId to return example DomainEvents
        exampleAdapterStub._findDomainEventsByAggregateId.withArgs(1).returns
          id: 1
          name: 'example'

        # instantiate the ReadExampleRepository with the stubbed Adapter and the ReadExample Class
        readExampleRepository = new ReadExampleRepository exampleAdapterStub, ReadExample

        # example start, end dates
        start = new Date 2013, 10, 1
        end = new Date 2014, 2, 1

        # ask the ReadExampleRepository to find ReagAggregates by DateRange
        readAggregates = readExampleRepository.findByDateRange start, end

        # expectations
        expect(readAggregates.length).to.be 1
        expect(readAggregates[0]).to.be.a ReadExample
        expect(readAggregates[0].name).to.be 'example'