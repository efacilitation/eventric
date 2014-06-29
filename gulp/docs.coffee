gulp        = require 'gulp'
dgeni       = require 'dgeni'
runSequence = require 'run-sequence'

module.exports = (gulp) ->

  gulp.task 'docs', (next) ->
    runSequence 'build', 'docs:generate', next

  gulp.task 'docs:generate', ->
    return dgeni.generator('docs/dgeni.conf.coffee')()
