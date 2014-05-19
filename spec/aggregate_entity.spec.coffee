describe 'AggregateEntity', ->
  Entity            = eventric 'AggregateEntity'
  EntityCollection  = eventric 'AggregateEntityCollection'

  describe '#getMetaData', ->

    it 'should return an object including the MetaData of the Entity', ->
      class MyEntity extends Entity

      myEntity = new MyEntity
      myEntity.id = 1

      expect(myEntity.getMetaData()).to.deep.equal
        id: 1
        name: 'MyEntity'

  describe '#getChanges', ->

    it 'should return changes to properties from the given entity', ->
      class MyEntity extends Entity

      myEntity = new MyEntity name: 'Willy'
      myEntity._set 'name', 'John'

      expect(myEntity.getChanges()).to.deep.equal
        props:
          name: 'John'
        entities: {}
        collections: {}

    it 'should return changes to properties from the given entity collection', ->
      class MyEntity extends Entity

      class MyThingsEntity extends Entity

      myEntity = new MyEntity
      myEntity._set 'things', new EntityCollection

      myThingsEntity = new MyThingsEntity name: 'NotWayne'
      myThingsEntity.id = 2
      myThingsEntity._set 'name', 'Wayne'

      myEntity._get('things').add myThingsEntity

      expect(myEntity.getChanges()).to.deep.equal
        props: {}
        entities: {}
        collections:
          things: [ {
            id: 2
            name: 'MyThingsEntity'
            changed:
              props:
                name: 'Wayne'
              entities: {}
              collections: {}
          } ]

    it 'should track changes to collections that are contained in other collections', ->
      class A extends Entity

      a1 = new A
      a1._set 'things', new EntityCollection

      a2 = new A
      a2.id = 2
      a2._set 'formics', new EntityCollection
      a2._set 'name', 'Wayne'

      a1._get('things').add a2

      a3 = new A
      a3.id = 3
      a3._set 'name', 'Rocks'

      a2._get('formics').add a3

      spy = sinon.spy a3, 'getChanges'

      a1.getChanges()

      expect(spy.calledOnce).to.be.true


  describe '#clearChanges', ->

    it 'should clear all changes', ->
      class A extends Entity

      a1 = new A()
      a1.id = 1
      a1._set 'things', new EntityCollection
      a1._set 'name', 'John'

      a2 = new A()
      a2.id = 2
      a2._set 'name', 'Wayne'

      a1._get('things').add a2

      a1.clearChanges()

      expect(a1.getChanges()).to.deep.equal {}

  describe '#applyChanges', ->

    it 'should apply given changes to properties and not track the changes', ->
      class MyEntity extends Entity

      myEntity = new MyEntity

      changedPropsAndCollections =
        props:
          name: 'ChangedJohn'

      myEntity.applyChanges changedPropsAndCollections

      expect(myEntity._get 'name').to.equal 'ChangedJohn'
      expect(myEntity.getChanges()).to.deep.equal {}


    it 'should apply given changes to properties and collections', ->

      class MyTopEntity extends Entity

      class MySubEntity extends Entity

      mytopentity = new MyTopEntity
      mytopentity._set 'topcollection', new EntityCollection

      mysubentity = new MySubEntity
      mysubentity.id = 1
      mysubentity._set 'name', 'Wayne'

      mytopentity._get('topcollection').add mysubentity

      changedPropsAndCollections =
        props: {}
        entities: {}
        collections:
          topcollection: [ {
            id: 1
            name: 'MySubEntity'
            changed:
              props:
                name: 'ChangedWayne'
              entities: {}
              collections: {}
          } ]


      mytopentity.applyChanges changedPropsAndCollections

      expect(mytopentity._get('topcollection').get(1)._get('name')).to.equal 'ChangedWayne'