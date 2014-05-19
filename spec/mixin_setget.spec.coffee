describe 'MixinSetGet', ->
  AggregateRoot = eventric 'AggregateRoot'

  exampleAggregate = null
  beforeEach ->
    class ExampleAggregate extends AggregateRoot
    exampleAggregate = new ExampleAggregate
    exampleAggregate._set 'someProperty', 'someValue'

  describe '#_set', ->

    it  'should set a property', ->
      expect(exampleAggregate._get('someProperty')).to.equal 'someValue'


  describe '#_get', ->

    it 'should get some property', ->
      expect(exampleAggregate._get('someProperty')).to.equal 'someValue'