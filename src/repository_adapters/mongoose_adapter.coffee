_ = require 'underscore'
EntityCollection = require('eventric')('AggregateEntityCollection')


class MongooseAdapter
  _mongooseModels: {}

  constructor: (@_mongoose = require 'mongoose') ->
    if @_entityName
      @_mongooseModel = @mongooseModel @_entityName, @_schema

  mongooseModel: (repoName, repoSchema) ->
    # singleton to avoid duplicated definition of schema/model
    if !@_mongooseModels[repoName]
      schema = new @_mongoose.Schema repoSchema
      @_mongooseModels[repoName] = @_mongoose.model(repoName, schema)
    @_mongooseModels[repoName]

  getSchema: () ->
    @_mongooseModel.schema

  getRepositoryForEntity: (entityName) ->
    require('sixsteps-server')("./repositories/#{entityName.toLowerCase()}_repository")

  save: (entity, next) ->
    doc = @_reflectEntityAttrsToNewMongooseDoc.call @, @_schema, entity
    #if entity has id set doc._id for update
    doc._id = entity._id if entity._id
    doc.save (err, result) =>
      return next err, null if err
      entity = @_reflectDocAttrsToNewEntity.call @, @._schema, result
      next null, entity

  #relation has to be the attribute hash in ParentSchema not the Relation Schema
  #i.e. if u want to populate RepositoryMeeting._schema.attendees relation = attendees
  find: (config, next) ->
    query = config.query or {}
    fields = config.fields or ''
    options = config.options or {}
    populate = config.populate
    foundDocs = []
    self = @
    #use lean to get plain javascript objects instead of mongoose documents
    request = @_mongooseModel.find(query, fields, options)
    if populate
      request.populate(populate)

    request.lean().exec (err, docs) ->
      return next err, null if err
      for doc in docs
        entity = self._reflectDocAttrsToNewEntity.call self, self._schema, doc
        if populate
          entity._props[populate] = self._reflectRelations populate, doc
        foundDocs.push entity
      next null, foundDocs

  findOne: (config, next) ->
    @find config, (err, docs) ->
      return next err, null if err
      next err, docs[0] || null

  findById: (id, populate, next) ->
    if typeof populate == 'function'
      next = populate
      populate = null

    self = @
    entity = null
    request = @_mongooseModel.findById id

    if populate
      request.populate populate

    request.lean().exec (err, doc) ->
      return next err, null if err
      if doc
        entity = self._reflectDocAttrsToNewEntity.call self, self._schema, doc
        if populate
          entity._props[populate] = self._reflectRelations populate, doc

      next null, entity

  delete: (config, next) ->
    @_mongooseModel.remove config, (err) ->
      next err

  # -- private methods --
  # reflect mongooseDocument attributes to vanilla entity
  _reflectDocAttrsToNewEntity: (schema, doc) ->
    entity = new @._entity()
    entity._id = doc._id

    for key, value of schema
      if value?[0] instanceof @_mongoose.Schema
        subrepo = new @_sub.repos[key]
        entity[key] = new EntityCollection
        _.each doc[key], (subvalue, subkey) =>
          entity[key].add @_reflectDocAttrsToNewEntity.call subrepo, subrepo._schema, subvalue

        # build query/command container here
      else
        entity._props[key] = doc[key]
    entity


  # reflect vanillaEntity attributes to mongooseDocument
  _reflectEntityAttrsToNewMongooseDoc: (schema, entity) ->
    doc = new @_mongooseModel

    for key,value of entity._props
      if schema[key]?[0] instanceof @_mongoose.Schema and entity[key] instanceof EntityCollection
        # reflect collections
        doc[key] = @_reflectCollectionsToMongooseDoc key, value
      else
        # reflect properties
        doc[key] = entity._props[key]

    doc

  _reflectCollectionsToMongooseDoc: (collectionName, collection) ->
    subdoc = []
    subrepo = new @_sub.repos[collectionName]
    for collectionEntity in collection.entities
      subentity = new subrepo._entity (collectionEntity._props)
      subdoc.push @_reflectEntityAttrsToNewMongooseDoc.call subrepo, subrepo._schema, subentity
    subdoc

  _reflectRelations: (relation, doc) ->
    result = []
    subrepo = (new @_sub.repos[relation])
    _.each doc[relation], (value) ->
      #TODO refactoring: should not return the comand entity use query entity instead!!!
      result.push @_reflectDocAttrsToNewEntity.call subrepo, subrepo._schema, value
    ,@
    result

module.exports = MongooseAdapter
