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
      'spec/helper/setup.coffee'
      'src/**/*.coffee'
      ])
      .pipe mocha(reporter: 'spec')
        .on('error', growl.specsError)


  gulp.task 'spec:client', (next) ->
    runSequence 'build', 'spec:client:vendor', 'spec:client:src', 'spec:client:run', next


  gulp.task 'spec:client:vendor', ->
    gulp.src([
      'node_modules/chai/chai.js'
      'node_modules/async/lib/async.js'
      'node_modules/mockery/mockery.js'
      'node_modules/sinon/lib/**/*.js'
      'node_modules/sinon-chai/lib/sinon-chai.js'
    ])
      .pipe(commonjs(
        pathModifier: (path) ->
          path = path.replace process.cwd(), ''
          path = path.replace /.js$/, ''
          sinonPath = '/node_modules/sinon/lib/'
          if (path.indexOf sinonPath) is 0
            path = path.replace sinonPath, ''
          else
            path = path.replace /.*\//, ''
          path
      ))
      .pipe(newer('build/spec/vendor.js'))
      .pipe(concat('vendor.js'))
      .pipe(gulp.dest('build/spec/'))


  gulp.task 'spec:client:src', (next) ->
    gulp.src([
      'src/**/*.spec.coffee'
    ])
      .pipe(coffee({bare: true}))
      .pipe(commonjs(
        autoRequire: true
        pathModifier: (path) ->
          path = path.replace "#{process.cwd()}/src", 'eventric'
          path = path.replace /.js$/, ''
          return path
      ))
      .pipe(gulp.dest('build/node/'))


  gulp.task 'spec:client:run', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
