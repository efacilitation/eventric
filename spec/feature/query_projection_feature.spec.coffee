describe 'Query Projection Feature', ->

  describe 'given we created and initialized some example context including a queryhandler', ->
    exampleContext = null
    beforeEach (done) ->
      exampleContext = eventric.context 'exampleContext'

      exampleContext.addQueryHandler 'getExample', (params, callback) ->
        @$getProjectionStore 'ExampleProjection', (err, projectionStore) ->
          callback null, projectionStore

      exampleContext.initialize =>
        done()


    describe 'when we query the context', ->
      it 'then the query should return the correct result', (done) ->
        exampleContext.query 'getExample', id: 1
        .then (result) =>
          expect(result).to.deep.equal {}
          done()
