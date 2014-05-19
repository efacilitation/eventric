describe 'AggregateEntityCollection', ->
  Entity           = eventric 'AggregateEntity'
  EntityCollection = eventric 'AggregateEntityCollection'

  entityCollection = undefined
  beforeEach ->
    entityCollection = new EntityCollection


  it 'should have a getter for the entities', ->
    expect(entityCollection.entities).to.be.a 'array'

  it 'should throw an exception on setting the entities', ->
    expect(-> entityCollection.entities = []).to.throw()

  it 'should have a length property', ->
    expect(entityCollection.length).to.equal 0

  it 'should throw an exception on setting the length', ->
    expect(-> entityCollection.length = 5).to.throw()

  describe 'on passing options', ->

    it 'should add the entities to the entityCollection', ->
      entityCollection = new EntityCollection
        entities: [new Entity()]
      expect(entityCollection._entities.length).to.equal 1

  describe '#add', ->

    it 'should add a entity to the entityCollection', ->
      entityCollection.add new Entity()
      expect(entityCollection._entities.length).to.equal 1

    it 'should add an array of entities to the entityCollection', ->
      entityCollection.add [new Entity(), new Entity(), new Entity()]
      expect(entityCollection._entities.length).to.equal 3


  describe '#remove', ->

    it 'should remove a entity from the entityCollection', ->
      entity = new Entity()
      entityCollection._entities.push entity
      entityCollection.remove entity
      expect(entityCollection._entities.length).to.equal 0


  describe '#get', ->

    it 'should return a entity with the given id', ->
      entity = new Entity()
      entity.id = 1
      entityCollection._entities.push entity
      expect(entityCollection.get 1).to.equal entity