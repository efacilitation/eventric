eventric = require 'eventric'
Clone = eventric.require 'HelperClone'
ObjectDiff = eventric.require 'HelperObjectDiff'

test = (oldObject, newObject) ->
  differences = ObjectDiff.getDifferences oldObject, newObject
  appliedObj = ObjectDiff.applyDifferences oldObject, differences
  expect(newObject).to.deep.equal appliedObj


describe.only 'Object Differences', ->
  oldObject = null
  newObject = null

  describe 'properties', ->

    beforeEach ->
      oldObject =
        foo: 'bar'
      newObject = Clone oldObject

    it 'should track and apply property changes', ->
      newObject.foo = 'moo'
      test oldObject, newObject

    it 'should track and apply property deletions', ->
      delete newObject.foo
      test oldObject, newObject

    it 'should track and apply property creations', ->
      newObject.foo2 = 'bar2'
      test oldObject, newObject

    it 'should track and apply property type changes', ->
      newObject.foo = 1
      test oldObject, newObject


  describe 'objects', ->

    it 'should track and apply empty object creations', ->
      oldObject = {}
      newObject = Clone oldObject
      newObject.foo = {}
      test oldObject, newObject


    it 'should track and apply pre filled object creations', ->
      oldObject = {}
      newObject = Clone oldObject
      newObject.foo =
        childFoo: 'childBar'
      test oldObject, newObject

    it 'should track and apply object property creations', ->
      oldObject =
        foo: {}
      newObject = Clone oldObject
      newObject.foo.bar = 'bar'
      test oldObject, newObject


    it 'should track and apply object property changes', ->
      oldObject =
        foo:
          childFoo: 'childBar'
      newObject = Clone oldObject
      newObject.foo.childFoo = 'childBar2'
      test oldObject, newObject


    it 'should track and apply object property deletions', ->
      oldObject =
        foo:
          childFoo: 'childBar'
      newObject = Clone oldObject
      delete newObject.foo.childFoo
      test oldObject, newObject


    it 'should track and apply object replacements', ->
      oldObject =
        foo:
          childFoo: 'childBar'
      newObject = Clone oldObject
      newObject.foo =
        childFoo2: 'childBar2'
      test oldObject, newObject


    it 'should track and apply object deletions', ->
      oldObject =
        foo:
          childFoo: 'childBar'
      newObject = Clone oldObject
      delete newObject.foo
      test oldObject, newObject


  describe 'arrays', ->

    it 'should track and apply empty array creations', ->
      oldObject = {}
      newObject = Clone oldObject
      newObject.array = []
      test oldObject, newObject


    it 'should track and apply pre filled array creations', ->
      oldObject = {}
      newObject = Clone oldObject
      newObject.array = [1, 2, 3]
      test oldObject, newObject


    it 'should track and apply push of new elements', ->
      oldObject =
        array: []
      newObject = Clone oldObject
      newObject.array.push 1
      test oldObject, newObject


    it 'should track and apply removal of elements', ->
      oldObject =
        array: [1]
      newObject = Clone oldObject
      newObject.array.pop()
      test oldObject, newObject


    it 'should track and apply value changes of elements', ->
      oldObject =
        array: [1]
      newObject = Clone oldObject
      newObject.array[0] = 2
      test oldObject, newObject


    it 'should track and apply property changes of object elements', ->
      oldObject =
        array: [foo: 'bar']
      newObject = Clone oldObject
      newObject.array[0].foo = 'baz'
      test oldObject, newObject


    it 'should track and apply array deletions', ->
      oldObject =
        array: []
      newObject = Clone oldObject
      delete newObject.array
      test oldObject, newObject


    it 'should track and apply array replacements', ->
      oldObject =
        array: [1, 2, 3]
      newObject = Clone oldObject
      newObject.array = [4, 5, 6]
      test oldObject, newObject


    it 'should track and apply movement of objects inside array', ->
      oldObject =
        array: [{foo: 'bar'}, {moo: 'cow'}]
      newObject = Clone oldObject
      first = Clone oldObject.array[0]
      second = Clone oldObject.array[1]
      newObject.array = [first, second]
      test oldObject, newObject


  describe 'advanced', ->
    beforeEach ->
      oldObject =
        someProp: 'bar'
        someObject: {foo: 'bar'}
        someArray: ['foo', 'bar']
        someNested:
          so: [
            'deep'
            'dig'
            {
              deeper: [
                'oh'
                {so: 'deep'}
              ]
            }
            {
              notsodeep: [
                'batman'
              ]
            }
          ]
      newObject = Clone oldObject
      newObject.someProp = 'moo'
      newObject.someNested.soNew = 'wat'
      newObject.someNested.someArray = []
      newObject.someNested.someArray[23] = 'yeah'
      newObject.someNested.someArray[42] = 'HAE'
      delete newObject.someNested.so[1]
      newObject.someNested.so[2].deeper[1].so = 'deepest'
      newObject.someNested.so[2].deeper[1].noes = 'gotchya'
      newObject.someNested.so[2].deeper.push 'TROLLFACE'
      deepObj = Clone newObject.someNested.so[2]
      notsodeepObj = Clone newObject.someNested.so[3]
      newObject.someNested.so[2] = notsodeepObj
      newObject.someNested.so[3] = deepObj


    it 'should track and apply the mixed changes', ->
      test oldObject, newObject


    it 'should be able to supply the differences in tree format', ->
      differences = ObjectDiff.getDifferences oldObject, newObject
      difftree = ObjectDiff.applyDifferences {}, differences

      diffObject = {}
      diffObject.someProp = 'moo'
      diffObject.someNested = {}
      diffObject.someNested.soNew = 'wat'
      diffObject.someNested.someArray = []
      diffObject.someNested.someArray[23] = 'yeah'
      diffObject.someNested.someArray[42] = 'HAE'
      diffObject.someNested.so = []
      diffObject.someNested.so[2] =
        notsodeep: [
          'batman'
        ]
      diffObject.someNested.so[3] =
        deeper: ['oh']

      diffObject.someNested.so[3].deeper[1] = {}
      diffObject.someNested.so[3].deeper[1].so = 'deepest'
      diffObject.someNested.so[3].deeper[1].noes = 'gotchya'
      diffObject.someNested.so[3].deeper.push 'TROLLFACE'

      expect(diffObject).to.deep.equal difftree
