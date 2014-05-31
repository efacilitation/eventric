describe 'MixinSetGet', ->
  AggregateRoot = eventric.require 'AggregateRoot'

  exampleAggregate = null
  beforeEach ->
    class ExampleAggregate extends AggregateRoot
    exampleAggregate = new AggregateRoot 'ExampleAggregate'
    exampleAggregate._set 'someProperty', 'someValue'

  describe '#_set', ->

    it  'should set a property', ->
      expect(exampleAggregate._get('someProperty')).to.equal 'someValue'


  describe '#_get', ->

    it 'should get some property', ->
      expect(exampleAggregate._get('someProperty')).to.equal 'someValue'