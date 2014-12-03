coffee      = require 'gulp-coffee'
karma       = require 'gulp-karma'
mocha       = require 'gulp-mocha'
commonjs    = require 'gulp-wrap-commonjs'
newer       = require 'gulp-newer'
concat      = require 'gulp-concat'
runSequence = require 'run-sequence'
fs          = require 'fs'
spawn       = require('child_process').spawn

growl = require './helper/growl'
growl.initialize()

module.exports = (gulp) ->
  lastSpecError = false
  gulp.task 'spec', (next) =>
    growl.specsRun()
    runSequence 'spec:server', 'spec:client', ->
      growl.specsEnd()
      next()


  mochaProcess = null
  gulp.task 'spec:server', (next) ->
    glob = [
      'src/setup.spec.coffee'
      'src/**/*.coffee'
      ]

    options = [
      '--compilers'
      'coffee:coffee-script/register'
      '--reporter'
      'spec'
      '--timeout',
      '5000'
    ]
    if mochaProcess and mochaProcess.kill
      mochaProcess.kill()
    mochaProcess = spawn(
      'node_modules/.bin/mocha'
      options.concat(glob)
      {}
      next
    )
    mochaProcess.stdout.on 'data', (data) ->
      process.stdout.write data.toString()
    mochaProcess.stderr.on 'data', (data) ->
      process.stderr.write data.toString()


  gulp.task 'spec:client', (next) ->
    runSequence 'build', 'build:spec', 'spec:client:run', next


  gulp.task 'spec:client:run', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
