describe 'MixinSetGet', ->

  expect   = require 'expect.js'
  eventric = require 'eventric'

  AggregateRoot = eventric 'AggregateRoot'

  exampleAggregate = null
  beforeEach ->
    class ExampleAggregate extends AggregateRoot
    exampleAggregate = new ExampleAggregate
    exampleAggregate._set 'someProperty', 'someValue'

  describe '#_set', ->

    it  'should set a property', ->
      expect(exampleAggregate._get('someProperty')).to.be 'someValue'


  describe '#_get', ->

    it 'should get some property', ->
      expect(exampleAggregate._get('someProperty')).to.be 'someValue'