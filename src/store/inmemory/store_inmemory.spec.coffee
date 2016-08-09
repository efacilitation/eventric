eventricStoreSpecs = require 'eventric-store-specs'
eventricStoreSpecs.runFor
  StoreClass: require './store_inmemory'
  initializeCallback: (store) ->
    store.initialize name: 'FakeContext'
