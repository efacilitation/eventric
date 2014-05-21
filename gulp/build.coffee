coffee      = require 'gulp-coffee'
concat      = require 'gulp-concat'
clean       = require 'gulp-clean'
commonjs    = require 'gulp-wrap-commonjs'
uglify      = require 'gulp-uglify'
runSequence = require 'run-sequence'

module.exports = (gulp) ->
  gulp.task 'build', ->
    runSequence 'build:clean', 'build:copyjs', 'build:src', 'build:release'

  gulp.task 'build:clean', ->
    gulp.src('build/**/*', read: false)
      .pipe(clean())

  gulp.task 'build:copyjs', ->
    gulp.src('src/*.js')
      .pipe(gulp.dest('build/src'))

  gulp.task 'build:src', ->
    gulp.src('src/*.coffee')
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/src'))

  gulp.task 'build:release', ->
    gulp.src('build/src/*.js')
      .pipe(commonjs(
        pathModifier: (path) ->
          path = path.replace "#{process.cwd()}/build/src", 'eventric'
          path = path.replace /.js$/, ''
          return path
        ))
      .pipe(concat('eventric.js'))
      .pipe(gulp.dest('build/release'))
      .pipe(uglify())
      .pipe(concat('eventric-min.js'))
      .pipe(gulp.dest('build/release'))
