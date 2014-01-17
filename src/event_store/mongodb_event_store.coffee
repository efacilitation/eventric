# this should go into its own module: eventric-mongodb-eventstore so we can test with mongodb
MongoClient = require('mongodb').MongoClient

class MongoDBEventStore

  initialize: (callback) ->

    MongoClient.connect 'mongodb://127.0.0.1:27017/events', (err, db) =>

      if err
        console.log 'MongoDB connection failed'
        callback? err, null

      else
        console.log 'MongoDB connected'
        @db = db
        callback? null



  save: (domainEvent, callback) ->

    @db.collection domainEvent.aggregate.name, (err, collection) ->
      collection.insert domainEvent, (err, doc) ->
        if err
          callback err

        else
          callback null



  findByAggregateId: (aggregateName, aggregateId, callback) ->

    @db.collection aggregateName, (err, collection) =>

      collection.find { 'aggregate.id': aggregateId }, (err, cursor) =>
        if err
          callback err, null
          return

        cursor.toArray (err, items) =>
          if err
            callback err, null
            return

          callback null, items


  findAggregateIds: ([aggregateName, query, projection]..., callback) ->

    @db.collection aggregateName, (err, collection) =>

      collection.find query, projection, (err, cursor) =>
        if err
          callback err, null
          return

        cursor.toArray (err, items) =>
          if err
            callback err, null
            return

          callback null, items


module.exports = MongoDBEventStore