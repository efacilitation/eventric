eventric = require 'eventric'

describe 'Example BoundedContext Feature', ->
  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created some example bounded context', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext
        name: 'exampleContext'
        store: eventStoreMock

      exampleContext.addAggregate 'Example', root: class Example


    describe 'when we command the bounded context to create an aggregate', ->
      props =
        some: 'props'
      beforeEach ->
        exampleContext.addCommand 'createExample', ->
          @aggregate.create 'Example', props, ->


      it 'then it should haved triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'Example:create', (domainEvent) ->
          expect(domainEvent.getName()).to.equal 'create'
          expect(domainEvent.getAggregateChanges()).to.deep.equal props
          done()

        exampleContext.command
          name: 'createExample'


    describe 'when we command the bounded context to command an aggregate', ->
      beforeEach ->
        eventStoreMock.find.yields null, [
          aggregate:
            id: 1
            name: 'Example'
            diff: [
              {
                type: 'added'
                path: [
                  {
                    key: 'entities'
                    valueType: 'array'
                  }
                ]
                value: []
              }
            ]
        ]

        class ExampleEntity
          someEntityFunction: ->
            @entityProp = 'bar'

        class ExampleRoot
          someRootFunction: (someId) ->
            @someId = someId
            @rootProp = 'foo'
            entity = new ExampleEntity
            entity.someEntityFunction()
            @entities[2] = entity

        exampleContext.addAggregate 'Example',
          root: ExampleRoot
          entities:
            'ExampleEntity': ExampleEntity

        exampleContext.addCommands
          someBoundedContextFunction: (params, callback) ->
            @aggregate.command 'Example', params.id, 'someRootFunction', 1, callback


      it 'then it should have triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'Example:someRootFunction', (domainEvent) ->
          changes = domainEvent.getAggregateChanges()
          expect(changes.entities[2].entityProp).to.equal 'bar'
          expect(domainEvent.getName()).to.equal 'someRootFunction'
          done()

        exampleContext.command
          name: 'someBoundedContextFunction'
          params:
            id: 1


    describe 'when we use a command which calls a previously added adapter function', ->
      ExampleAdapter = null
      beforeEach ->
        class ExampleAdapter
          someAdapterFunction: sandbox.stub()
        exampleContext.addAdapter 'exampleAdapter', ExampleAdapter

        exampleContext.addApplicationService
          commands:
            doSomething: (params, callback) ->
              @adapter('exampleAdapter').someAdapterFunction()
              callback()


      it 'then it should have called the adapter function', (done) ->
        exampleContext.command
          name: 'doSomething'
        , ->
          expect(ExampleAdapter::someAdapterFunction).to.have.been.calledOnce
          done()


    describe 'when we query the bounded context without an explicitly added read aggregate', ->
      beforeEach ->
        eventStoreMock.find.yields null, [
          aggregate:
            id: 1
            name: 'Example'
            diff: [
              {
                type: 'added'
                path: [
                  {
                    key: 'foo'
                    valueType: 'string'
                  }
                ]
                value: 'bar'
              }
            ]
        ]

        exampleContext.addQueries
          getExample: (params, callback) ->
            @repository('Example').findById 1, (err, readExample) ->
              callback null, readExample


      it 'then it should return some default read aggregate', (done) ->
        exampleContext.query
          name: 'getExample'
        .then (readExample) ->
          expect(readExample.foo).to.equal 'bar'
          done()



    describe 'when we query the bounded context with an explicitly added read aggregate', ->
      beforeEach ->
        eventStoreMock.find.yields null, [
          aggregate:
            id: 1
            name: 'Example'
            diff: [
              {
                type: 'added'
                path: [
                  {
                    key: 'foo'
                    valueType: 'string'
                  }
                ]
                value: 'bar'
              }
            ]
        ]

        exampleContext.addReadAggregate 'Example', root: class Example
          getFoo: ->
            @foo

        exampleContext.addApplicationService
          queries:
            getExample: (params, callback) ->
              @repository('Example').findById 1, callback


      it 'then it should return the correct read aggregate', (done) ->
        exampleContext.query
          name: 'getExample'
          , (err, readExample) ->
            expect(readExample.getFoo()).to.equal 'bar'
            done()


    describe 'when we query the bounded context with an explicitly added read aggregate repository', ->
      beforeEach ->
        eventStoreMock.find.yields null, [
          aggregate:
            id: 1
            name: 'Example'
            diff: [
              {
                type: 'added'
                path: [
                  {
                    key: 'foo'
                    valueType: 'string'
                  }
                ]
                value: 'bar'
              }
            ]
        ]

        exampleContext.addRepository 'Example',
          findByExample: (callback) ->
            @find {}, callback

        exampleContext.addQuery 'getExample', (params, callback) ->
          @repository('Example').findByExample callback


      it 'then it should return the correct read aggregate', (done) ->
        exampleContext.query
          name: 'getExample'
          , (err, readExample) ->
            expect(readExample[0].foo).to.equal 'bar'
            done()
