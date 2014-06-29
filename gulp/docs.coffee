gulp  = require 'gulp'
dgeni = require 'dgeni'

module.exports = (gulp) ->

  gulp.task 'docs', ->
    return dgeni.generator('docs/dgeni.conf.coffee')()
