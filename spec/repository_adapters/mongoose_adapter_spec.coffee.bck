describe.skip 'RepositoryMongooseAdapter', ->

  expect    = null
  mongoose  = null
  mockgoose = null

  Repository       = null
  Entity           = null
  EntityCollection = null
  Validator        = null
  validations      = null
  repo             = null

  Attendee           = null
  Topic              = null
  Meeting            = null
  TopicRepository    = null
  AttendeeRepository = null
  MeetingRepository  = null

  before ->
    expect              = require 'expect'
    mongoose            = require 'mongoose'
    mockgoose           = require 'mockgoose'
    Repository          = require('sixsteps-server')('Repository')
    Entity              = require('eventric')('AggregateEntity')
    EntityCollection    = require('eventric')('AggregateEntityCollection')
    AggregateRoot       = require('eventric')('AggregateRoot')
    Validator           = require('sixsteps-shared')('Validator')
    validations         = require('sixsteps-shared')('validations')

    class Attendee extends Entity
      _entityName: 'Attendee'
      @props 'name'

    class Topic extends Entity
      _entityName: 'Topic'
      @props 'title', 'order'

    class Meeting extends AggregateRoot
      _entityName: 'Meeting'
      @props 'title', 'attendees', 'topics'

    class TopicRepository extends Repository
      _entity: Topic
      _entityName: 'Topic'
      _schema:
        title:
          type: String
        order:
          type: Number

    class AttendeeRepository extends Repository
      _entity: Attendee
      _entityName:'Attendee'
      _schema:
        name:
          type: String

    class MeetingRepository extends Repository
      _entity: Meeting
      _entityName: 'Meeting'
      _sub:
        repos:
          topics: TopicRepository
          attendees: AttendeeRepository
      _schema:
        title:
          type: String
        attendees:[
          type: mongoose.Schema.ObjectId
          ref: 'Attendee'
        ]
        topics: [new TopicRepository().getSchema()]

  before ->
    #mongoose.connect('mongodb://localhost/test')
    mockgoose(mongoose)

  after ->
    #mongoose.connection.db.dropDatabase()
    #mongoose.disconnect()
    mockgoose.reset()

  beforeEach ->
    repo = new MeetingRepository

  describe '#mongooseModel', ->
    it 'should be a function', ->
      repo = new Repository
      expect(repo.mongooseModel).to.be.a('function')

    it 'should return an instance of mongoose.Model which includes an mongoose.Schema', ->
      repo = new MeetingRepository
      doc = new repo._mongooseModel
      expect(doc).to.be.a(mongoose.Model)
      expect(doc.schema).to.be.a(mongoose.Schema)

  describe '#_reflectDocAttrsToNewEntity', ->
    it 'should return a new entity with attributes reflected from doc based on schema', (done) ->
      title = '_reflectDocAttrsToNewEntity'
      doc = new repo._mongooseModel
      doc.title = title

      doc.save (err, savedMeeting) ->
        entity = repo._reflectDocAttrsToNewEntity repo._schema, doc
        expect(entity.title).to.be(title)
        done()

    it 'should return a new entity with attributes reflected from doc based on schema including one subdocument', (done) ->
      title = '_reflectDocAttrsToNewEntity'
      topicTitle = '_reflectTopicTitle'
      doc = new repo._mongooseModel
      doc.title = title
      doc.topics.push title:topicTitle
      doc.save (err, savedMeeting) ->
        entity = repo._reflectDocAttrsToNewEntity repo._schema, doc
        expect(entity.title).to.be(title)
        expect(entity.topics).to.be.a EntityCollection
        expect(entity.topics.entities[0]).to.be.a(Topic)
        expect(entity.topics.entities[0].title).to.be(topicTitle)
        done()

    it 'should return a new entity with attributes reflected from doc based on schema including two subdocuments', (done) ->
      title = '_reflectDocAttrsToNewEntity'
      topicTitle = '_reflectTopicTitle'
      topicTitle2 = '_reflectTopicTitle2'
      doc = new repo._mongooseModel
      doc.title = title
      doc.topics.push title:topicTitle
      doc.topics.push title:topicTitle2
      doc.save (err, savedMeeting) ->
        entity = repo._reflectDocAttrsToNewEntity repo._schema, doc
        expect(entity.title).to.be(title)
        expect(entity.topics.entities[0]).to.be.a(Topic)
        expect(entity.topics.entities[0].title).to.be(topicTitle)
        expect(entity.topics.entities[1]).to.be.a(Topic)
        expect(entity.topics.entities[1].title).to.be(topicTitle2)
        done()

  describe '#_reflectEntityAttrsToNewMongooseDoc', ->
    it 'should return a new doc with attributes reflected from entity', ->
      title = '_reflectEntityAttrsToNewMongooseDoc'
      meeting = new Meeting()
      meeting.title = title

      doc = repo._reflectEntityAttrsToNewMongooseDoc(repo._schema, meeting)
      expect(doc.title).to.be(title)

    it 'should return a new doc with attributes reflected from entity including one subdocument', ->
      title = '_reflectEntityAttrsToNewMongooseDoc'
      topicTitle = '_reflectTopicTitle'
      topic = new Topic {title: topicTitle}
      meeting = new Meeting()
      meeting.topics = new EntityCollection
      meeting.title = title

      meeting.topics.add topic

      doc = repo._reflectEntityAttrsToNewMongooseDoc(repo._schema, meeting)
      expect(doc.title).to.be(title)
      expect(doc.topics[0].title).to.be(topicTitle)
      expect(doc.topics[0]).to.be.ok()

  describe 'Relations', ->

    meetingId = null
    meetingTitle = null
    attendeeTitle = null

    beforeEach (done) ->
      meetingTitle = 'TestAttendeeRelation'
      attendeeTitle = 'Attendee1'
      attendeeRepo = new AttendeeRepository()

      attendee = new attendeeRepo._entity
      attendee.name = attendeeTitle

      meeting = new repo._entity
      meeting.title = meetingTitle
      meeting.attendees = []

      attendeeRepo.save attendee, (err, attendeeSaved) ->
        throw err if err
        meeting.attendees.push attendeeSaved._id

        repo.save meeting, (err, meetingSaved) ->
          throw err if err
          meetingId = meetingSaved._id
          done()

    it 'should populate attendees with findById', (done) ->
      repo.findById meetingId, 'attendees', (err, result) ->
        throw err if err
        expect(result.attendees.length).to.be(1)
        expect(result.attendees[0]).to.be.a Attendee
        expect(result.attendees[0].name).to.be attendeeTitle
        done()

    it 'should populate attedee with find', (done) ->
      repo.find {query: {title:meetingTitle}, populate: 'attendees'}, (err, result) ->
        throw err if err
        expect(result[0].attendees[0].name ).to.be attendeeTitle
        done()

  describe '#save', ->
    it 'should save a entity', (done) ->
      title = '#saveEntityToMongoose'
      meeting = new Meeting
      meeting.title = title

      repo.save meeting, (err, result) ->
        throw err if err
        expect(result.title).to.be title
        done()

    it 'should update a entity', (done) ->
      title = "#saveEntityToMongoose"
      updateTitle = "#updateEntityToMongoose"
      meeting = new Meeting()
      meeting.title = title

      repo.save meeting, (err, saveResult) ->
        throw err if err
        saveResult.title = updateTitle
        repo.save saveResult, (err, updateResult) ->
          expect(updateResult.title).to.be updateTitle
          expect(updateResult._id).to.be saveResult._id
          done()

  describe '#delete', ->
    it 'should delete a entity from the db by ID', (done) ->
      title = '#deleteEntityFromMongoose'
      meeting = new Meeting title:title

      repo.save meeting, (err, saveResult) ->
        throw err if err
        repo.delete _id: saveResult._id, (err) ->
          throw err if err
          repo.findById saveResult, (err,findResult) ->
            expect(findResult).to.be null
            done()

    it 'should delete a entity from the db by title', (done) ->
      title = '#deleteEntityFromMongoose'
      meeting = new Meeting title:title

      repo.save meeting, (err, saveResult) ->
        throw err if err
        repo.delete title: title, (err) ->
          throw err if err
          repo.findOne query: title:title, (err, findResult) ->
            expect(findResult).to.be null
            done()

  describe '#findById', ->
    it 'should find a entity by id', (done) ->
      title = '#saveEntityToMongoose'
      meeting = new Meeting title: title

      repo.save meeting, (err, result) ->
        throw err if err
        repo.findById result, (err, found) ->
          throw err if err
          expect(found.title).to.be title
          done()

    it 'should return null if nothing found', (done)->
      repo.findById 'someId', (err,result) ->
        expect(result).to.be null
        done()

  describe '#find', ->
    it 'should find entities by title', (done) ->
      title = '#saveEntityToMongoose'
      meeting = new Meeting title: title

      repo.save meeting, (err, result) ->
        throw err if err
        repo.find query: title: title, (err, found) ->
          throw err if err
          expect(found[0].title).to.be title
          done()

    it 'should return an empty array if nothing found', (done)->
      repo.find query: id:'someId', (err,result) ->
        expect(result.length).to.be 0
        done()

  describe '#findOne', ->
    it 'should find one entity by title', (done) ->
      title = '#saveEntityToMongoose'
      meeting = new Meeting title: title

      repo.save meeting, (err, result) ->
        throw err if err
        repo.findOne query: title: title, (err, found) ->
          throw err if err
          expect(found.title).to.be title
          done()

    it 'should return null if nothing found', (done) ->
      repo.findOne query: _id:'someId', (err,result) ->
        expect(result).to.be null
        done()
