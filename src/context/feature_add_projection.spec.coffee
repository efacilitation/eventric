describe 'Add Projection Feature', ->

  describe 'given we created and initialized some example context including a projection', ->
    ProjectionStub = null
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'exampleContext'

      class ProjectionStub
        initialize: sandbox.stub().yields()
      exampleContext.addProjection 'SomeProjection', ProjectionStub


    describe 'when we initialize the context', ->

      it 'then the initialize method of the projection should have been called', (done) ->
        exampleContext.initialize ->
          expect(ProjectionStub::initialize).to.have.been.called
          done()
