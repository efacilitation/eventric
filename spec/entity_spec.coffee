describe 'Entity', ->

  expect            = require 'expect'
  sinon             = require 'sinon'
  Entity            = require('eventric')('Entity')
  EntityCollection  = require('eventric')('EntityCollection')

  it 'should implement backbone events', ->
    entity = new Entity
    expect(entity._events).not.to.be 'undefined'

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


  describe '#_data', ->

    it 'should return an object including some EntityData', ->
      class A extends Entity
        _entityName: 'A'

      a = new A()
      a.id = 1

      expect(a._data()).to.eql
        id: 1
        entity: 'A'

  describe '#_changes', ->

    it 'should return changes to properties from the given entity', ->
      class A extends Entity
        _entityName: 'A'
        @prop 'name'

      a1 = new A name: 'Willy'
      a1.name = 'John'

      expect(a1._changes()).to.eql
        props:
          name: 'John'
        collections: {}

    it 'should return changes to properties from the given entity collection', ->
      class A extends Entity
        _entityName: 'A'
        @prop 'name'
        @prop 'things'

      a1 = new A
      a1.things = new EntityCollection

      a2 = new A name: 'NotWayne'
      a2.id = 2
      a2.name = 'Wayne'

      a1.things.add a2

      expect(a1._changes()).to.eql
        props: {}
        collections:
          things: [ {
            data:
              entity: 'A'
              id: 2
            props:
              name: 'Wayne'
            collections: {}
          } ]

    it 'should track changes to collections that are contained in other collections', ->
      class A extends Entity
        _entityName: 'A'
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

      spy = sinon.spy a3, '_changes'

      a1._changes()

      expect(spy.calledOnce).to.be.ok()


  describe '#_clearChanges', ->

    it 'should clear all changes', ->
      class A extends Entity
        _entityName: 'A'
        @props 'name', 'things'

      a1 = new A()
      a1.id = 1
      a1.things = new EntityCollection
      a1.name = 'John'

      a2 = new A()
      a2.id = 2
      a2.name = 'Wayne'

      a1.things.add a2

      a1._clearChanges()

      expect(a1._propsChanged).to.eql {}
      expect(a1.things.entities[0]._propsChanged).to.eql {}

  describe '#_applyChanges', ->

    it 'should apply given changes to properties', ->
      class MyEntity extends Entity
        _entityName: 'MyEntity'
        @props 'name'

      myEntity = new MyEntity
      myEntity.name = 'John'

      changedPropsAndCollections =
        props:
          name: 'ChangedJohn'

      myEntity._applyChanges changedPropsAndCollections

      expect(myEntity.name).to.eql 'ChangedJohn'


    it 'should apply given changes to properties and collections', ->

      class MyTopEntity extends Entity
        _entityName: 'MyTopEntity'
        @props 'topcollection'

      class MySubEntity extends Entity
        _entityName: 'MySubEntity'
        @props 'name'

      mytopentity = new MyTopEntity
      mytopentity.topcollection = new EntityCollection

      mysubentity = new MySubEntity
      mysubentity.id = 1
      mysubentity.name = 'Wayne'

      mytopentity.topcollection.add mysubentity

      changedPropsAndCollections =
        props: {}
        collections:
          topcollection: [ {
            data:
              entity: 'MySubEntity'
              id: 1
            props:
              name: 'ChangedWayne'
            collections: {}
          } ]


      mytopentity._applyChanges changedPropsAndCollections

      expect(mytopentity.topcollection.get(1).name).to.eql 'ChangedWayne'