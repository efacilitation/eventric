describe 'AggregateEntity', ->

  expect            = require 'expect.js'
  sinon             = require 'sinon'
  eventric          = require 'eventric'
  Entity            = eventric 'AggregateEntity'
  EntityCollection  = eventric 'AggregateEntityCollection'

  describe '#getMetaData', ->

    it 'should return an object including the MetaData of the Entity', ->
      class MyEntity extends Entity

      myEntity = new MyEntity
      myEntity.id = 1

      expect(myEntity.getMetaData()).to.eql
        id: 1
        name: 'MyEntity'

  describe '#getChanges', ->

    it 'should return changes to properties from the given entity', ->
      class MyEntity extends Entity
        @prop 'name'

      myEntity = new MyEntity name: 'Willy'
      myEntity.name = 'John'

      expect(myEntity.getChanges()).to.eql
        props:
          name: 'John'
        entities: {}
        collections: {}

    it 'should return changes to properties from the given entity collection', ->
      class MyEntity extends Entity
        @prop 'name'
        @prop 'things'

      class MyThingsEntity extends Entity
        @prop 'name'

      myEntity = new MyEntity
      myEntity.things = new EntityCollection

      myThingsEntity = new MyThingsEntity name: 'NotWayne'
      myThingsEntity.id = 2
      myThingsEntity.name = 'Wayne'

      myEntity.things.add myThingsEntity

      expect(myEntity.getChanges()).to.eql
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
        @props 'name', 'things', 'formics'

      a1 = new A
      a1.things = new EntityCollection

      a2 = new A
      a2.id = 2
      a2.formics = new EntityCollection
      a2.name = 'Wayne'

      a1.things.add a2

      a3 = new A
      a3.id = 3
      a3.name = 'Rocks'

      a2.formics.add a3

      spy = sinon.spy a3, 'getChanges'

      a1.getChanges()

      expect(spy.calledOnce).to.be.ok()


  describe '#clearChanges', ->

    it 'should clear all changes', ->
      class A extends Entity
        @props 'name', 'things'

      a1 = new A()
      a1.id = 1
      a1.things = new EntityCollection
      a1.name = 'John'

      a2 = new A()
      a2.id = 2
      a2.name = 'Wayne'

      a1.things.add a2

      a1.clearChanges()

      expect(a1.getChanges()).to.eql
        props: {}
        entities: {}
        collections: {}

  describe '#applyChanges', ->

    it 'should apply given changes to properties and not track the changes', ->
      class MyEntity extends Entity
        @props 'name'

      myEntity = new MyEntity

      changedPropsAndCollections =
        props:
          name: 'ChangedJohn'

      myEntity.applyChanges changedPropsAndCollections

      expect(myEntity.name).to.eql 'ChangedJohn'
      expect(myEntity.getChanges()).to.eql
        props: {}
        entities: {}
        collections: {}


    it 'should apply given changes to properties and collections', ->

      class MyTopEntity extends Entity
        @props 'topcollection'

      class MySubEntity extends Entity
        @props 'name'

      mytopentity = new MyTopEntity
      mytopentity.topcollection = new EntityCollection

      mysubentity = new MySubEntity
      mysubentity.id = 1
      mysubentity.name = 'Wayne'

      mytopentity.topcollection.add mysubentity

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

      expect(mytopentity.topcollection.get(1).name).to.eql 'ChangedWayne'





  describe '#prop', ->

    it 'should be defined', ->
      class A extends Entity
      expect(A.prop).to.be.a 'function'

    it 'should provide a default setter and getter for a property', ->
      class B extends Entity
        @prop 'name'

      b = new B()
      b.name = 'Steve'
      expect(b.name).to.be 'Steve'

    it 'should override the setter', ->
      class C extends Entity

        @prop 'name'
        @prop 'birthyear',
          set: (val) ->
            @_birthyear = val
            @_props['age'] = 2013 - @_birthyear

        @prop 'age',
          set: (val) -> throw "Don't set age directly"

      c = new C()
      c.birthyear = 2000
      expect(c.age).to.be 13

    it 'should override the getter', ->
      class D extends Entity
        @prop 'name'
        @prop 'welcomeMessage',
          set: (val) -> throw "Don't set welcomeMessage directly"
          get: ->
            "Hello #{@name}!"

      d = new D()
      d.name = 'Hans'
      expect(d.welcomeMessage).to.be 'Hello Hans!'

    it 'should keep track of changes', ->
      class E extends Entity
        @prop 'name'

      e = new E()
      e.name = 'Wayne'
      expect(e._propsChanged.name).to.be 'Wayne'

    it 'should not keep track of property changes if _trackPropsChanged is set to false', ->
      class E extends Entity
        @prop 'name'

      e = new E()
      e._trackPropsChanged = false
      e.name = 'Wayne'
      expect(e._propsChanged.name).to.be undefined

