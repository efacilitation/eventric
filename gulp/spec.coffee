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
    if !fs.existsSync 'node_modules/eventric'
      fs.symlinkSync '..', 'node_modules/eventric', 'dir'

    gulp.src([
      'spec/helper/setup.coffee'
      'spec/**/*.coffee'
      'src/**/*.coffee'
      ])
      .pipe mocha(reporter: 'spec')
        .on('error', growl.specsError)


  gulp.task 'spec:client', (next) ->
    runSequence 'build', 'spec:client:helper', 'spec:client:run', next


  gulp.task 'spec:client:helper', ->
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
      .pipe(newer('build/spec/helper.js'))
      .pipe(concat('helper.js'))
      .pipe(gulp.dest('build/spec/'))


  gulp.task 'spec:client:run', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
