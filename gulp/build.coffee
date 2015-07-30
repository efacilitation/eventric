coffee      = require 'gulp-coffee'
concat      = require 'gulp-concat'
commonjs    = require 'gulp-wrap-commonjs'
uglify      = require 'gulp-uglify'
rimraf      = require 'rimraf'
runSequence = require 'run-sequence'
mergeStream = require 'merge-stream'

module.exports = (gulp) ->
  gulp.task 'build', (next) ->
    runSequence 'build:clean', 'build:src', 'build:dist', next

  gulp.task 'build:clean', (next) ->
    rimraf './build', next

  gulp.task 'build:src', ->
    gulp.src([
      'src/**/*.coffee'
      '!**/*.spec.coffee'
    ])
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/src'))

  gulp.task 'build:dist', ->
    commonJsRequire = gulp.src 'node_modules/commonjs-require/commonjs-require.js'

    eventricSource = gulp.src([
      'build/src/**/*.js'
      '!**/*.spec.js'
      ])
      .pipe(commonjs(
        pathModifier: (path) ->
          path = path.replace "#{process.cwd()}/build/src", 'eventric'
          path = path.replace /.js$/, ''
          return path
      ))

    mergeStream commonJsRequire, eventricSource
      .pipe(concat('eventric.js'))
      .pipe(gulp.dest('build/dist'))
      .pipe(uglify())
      .pipe(concat('eventric-min.js'))
      .pipe(gulp.dest('build/dist'))


  gulp.task 'build:spec', ['build:spec:src', 'build:spec:vendor']


  gulp.task 'build:spec:src', (next) ->
    gulp.src([
      'src/**/*spec.coffee'
    ])
      .pipe(coffee({bare: true}))
      .pipe(commonjs(
        autoRequire: true
        pathModifier: (path) ->
          path = path.replace "#{process.cwd()}/src", 'eventric'
          path = path.replace /.js$/, ''
          return path
      ))
      .pipe(gulp.dest('build/src/'))


  gulp.task 'build:spec:vendor', ->
    gulp.src([
      'node_modules/chai/chai.js'
      'node_modules/async/lib/async.js'
      'node_modules/es6-promise/dist/es6-promise.js'
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
          else if path.indexOf('es6-promise') > -1
            path = 'es6-promise'
          else
            path = path.replace /.*\//, ''
          path
      ))
      .pipe(concat('vendor.js'))
      .pipe(gulp.dest('build/helper/spec/'))
