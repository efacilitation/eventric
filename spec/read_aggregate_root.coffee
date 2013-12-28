describe 'ReadAggregateRoot', ->

  expect = require 'expect'
  ReadAggregateRoot = require('eventric').ReadAggregateRoot

  readAggregateRoot = null
  beforeEach ->
    readAggregateRoot = new ReadAggregateRoot

  it 'should implement backbone events', ->
    expect(readAggregateRoot._events).not.to.be 'undefined'

  describe '#prop', ->

    class A extends ReadAggregateRoot
      @prop 'name'

    a = null
    beforeEach ->
      a = new A

    it 'should provide a default setter and getter for a property', ->
      a.name = 'Steve'
      expect(a._props.name).to.be 'Steve'
      expect(a.name).to.be 'Steve'

    it 'should trigger change event', ->
      changed = false
      a.on 'change:name', ->
        changed = true
      a.name = 'Alex'
      expect(changed).to.be.ok()

  describe '#props', ->
    # TODO

  describe '#toJSON', ->

    it 'should clone the props hash', ->
      expect(readAggregateRoot.toJSON()).not.to.be readAggregateRoot._props
      expect(readAggregateRoot.toJSON()).to.eql readAggregateRoot._props
