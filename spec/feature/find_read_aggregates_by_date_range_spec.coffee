describe 'Find ReadAggregates By Date Range Scenario', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  EventStore              = eventric 'MongoDBEventStore'

  describe 'given we want to get all ReadExampleAggregates between two dates', ->

    describe 'when we ask the ReadExampleRepository to find the matching ReadAggregates', ->

      it 'then it should return the corresponding list of ReadExampleAggregates', (done) ->
        # Example Classes
        class ReadExample extends ReadAggregateRoot

        class ReadExampleRepository extends ReadAggregateRepository

          constructor: ->
            super
            @registerClass 'ReadExample', ReadExample

          findByDateRange: (start, end, callback) ->
            # criteria not actually used here, just to show how it could look like
            exampleQuery =
              'name': 'create'
              'timestamp':
                $gte: start
                $lt: end

            @find 'ReadExample', exampleQuery, (err, readAggregates) =>
              callback null, readAggregates

        # create EventStoreStub and yield fake event
        EventStoreStub = sinon.createStubInstance EventStore
        EventStoreStub.find.yields null, [
          name: 'testEvent'
          aggregate:
            changed:
              props:
                name: 'example'
        ]

        # instantiate the ReadExampleRepository with the stubbed Adapter and the ReadExample Class
        readExampleRepository = new ReadExampleRepository 'Example', EventStoreStub
        readExampleRepository.findIds = sinon.stub().yields null, [42]

        # example start, end dates
        start = new Date 2013, 10, 1
        end = new Date 2014, 2, 1

        # ask the ReadExampleRepository to find ReagAggregates by DateRange
        readAggregates = readExampleRepository.findByDateRange start, end, (err, readAggregates) ->
          # expectations
          expect(readAggregates.length).to.be 1
          expect(readAggregates[0]).to.be.a ReadExample
          expect(readAggregates[0]._get 'name').to.be 'example'

          done()