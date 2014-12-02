coffee      = require 'gulp-coffee'
karma       = require 'gulp-karma'
mocha       = require 'gulp-mocha'
commonjs    = require 'gulp-wrap-commonjs'
newer       = require 'gulp-newer'
concat      = require 'gulp-concat'
runSequence = require 'run-sequence'
fs          = require 'fs'

growl = require './helper/growl'
growl.initialize()

module.exports = (gulp) ->
  lastSpecError = false
  gulp.task 'spec', (next) =>
    growl.specsRun()
    runSequence 'spec:server', 'spec:client', ->
      growl.specsEnd()
      next()


  gulp.task 'spec:server', =>
    gulp.src([
      'src/setup.spec.coffee'
      'src/**/*.coffee'
      ])
      .pipe mocha(reporter: 'spec')
        .on('error', growl.specsError)


  gulp.task 'spec:client', (next) ->
    runSequence 'build', 'build:spec', 'spec:client:run', next


  gulp.task 'spec:client:run', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
