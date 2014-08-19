gulp        = require 'gulp'
Dgeni       = require 'dgeni'
runSequence = require 'run-sequence'

module.exports = (gulp) ->

  gulp.task 'docs', (next) ->
    runSequence 'build', 'docs:generate', next

  gulp.task 'docs:generate', ->
    try
      dgeni = new Dgeni([require('../docs/dgeni.conf')]);
      dgeni.generate();
    catch e
      throw e
