describe 'ReadAggregateRoot', ->

  expect            = require 'expect'
  eventric          = require 'eventric'
  ReadAggregateRoot = eventric 'ReadAggregateRoot'


  describe '#constructor', ->

    it 'should apply the given AggregateData', ->

      aggregateData =
        id: 42
        name: 'Ender'

      readAggregate = new ReadAggregateRoot aggregateData

      expect(readAggregate.id).to.be 42
      expect(readAggregate.name).to.be 'Ender'