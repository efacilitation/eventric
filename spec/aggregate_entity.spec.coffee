describe 'AggregateEntity', ->
  AggregateEntity = eventric.require 'AggregateEntity'

  describe '#getMetaData', ->
    it 'should return an object including the MetaData of the Entity', ->
      myEntity = new AggregateEntity 'MyEntity'
      myEntity.id = 1

      expect(myEntity.getMetaData()).to.deep.equal
        id: 1
        name: 'MyEntity'


  describe '#getChanges', ->
    it 'should return changes to nested properties from the given entity', ->
      myEntity = new AggregateEntity 'myEntity', name: 'Willy'
      myEntity.some =
        thing:
          name: 'John'

      expect(myEntity.getChanges()).to.deep.equal
        some:
          thing:
            name: 'John'


    it 'should return a change to a property even if its the same value', ->
      myEntity = new AggregateEntity 'myEntity', name: 'Willy'
      myEntity.name = 'Willy'

      expect(myEntity.getChanges()).to.deep.equal
        name: 'Willy'


  describe '#clearChanges', ->
    it 'should clear all changes', ->
      a1 = new AggregateEntity 'A1'
      a1.id = 1
      a1.name = 'John'
      a1.clearChanges()
      expect(a1.getChanges()).to.deep.equal {}


  describe '#applyChanges', ->
    it 'should apply given changes to properties and not track the changes', ->
      myEntity = new AggregateEntity 'MyEntity'

      props =
        name: 'ChangedJohn'
        nested:
          structure: 'foo'
      myEntity.applyChanges props

      expect(myEntity.name).to.equal 'ChangedJohn'
      expect(myEntity.nested.structure).to.equal 'foo'
      expect(myEntity.getChanges()).to.deep.equal {}
