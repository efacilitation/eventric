gulp        = require 'gulp'
Dgeni       = require 'dgeni'
runSequence = require 'run-sequence'
coffee      = require 'gulp-coffee'
jade        = require 'gulp-jade'
path        = require 'canonical-path'
webserver   = require 'gulp-webserver'
gutil       = require 'gulp-util'
scss        = require 'gulp-sass'
concat      = require 'gulp-concat'


module.exports = (gulp) ->

  outputFolder = 'build/docs'
  bowerFolder = 'bower_components'

  copyComponent = (component, pattern, sourceFolder, packageFile) ->
    pattern = pattern or "/**/*"
    sourceFolder = sourceFolder or bowerFolder
    packageFile = packageFile or "bower.json"
    version = require(path.resolve(sourceFolder, component, packageFile)).version
    gulp.src(sourceFolder + "/" + component + pattern).pipe gulp.dest(outputFolder + "/components/" + component + "-" + version)


  gulp.task 'docs:build', (next) ->
    runSequence 'build', 'docs:generate:dgeni', 'docs:generate:jade', 'docs:generate:coffee', 'docs:generate:scss', 'docs:assets', 'docs:webserver:start', next


  gulp.task 'docs:watch', (next) ->
    gulp.run [
      "docs:build"
    ]

    gulp.watch [
      "docs/app/**/*.jade"
    ], ['docs:generate:jade']

    gulp.watch [
      "docs/app/**/*.coffee"
    ], ['docs:generate:coffee']
    
    gulp.watch [
      "docs/app/**/*.scss"
    ], ['docs:generate:scss']


  gulp.task 'docs', ->
    gutil.log "# Documentation Tasks:"
    gutil.log gutil.colors.cyan("'$ gulp docs:build'"), "build all once"
    gutil.log gutil.colors.cyan("'$ gulp docs:watch'"), "build all and start a webserver on port 8000 plus watch changing files"


  gulp.task 'docs:assets', ->
    copyComponent 'jquery', '/dist/*'
    copyComponent 'angularjs', '/*'
    copyComponent 'bootstrap', '/dist/**/*'
    copyComponent 'angular-ui-router', '/release/*'


  gulp.task 'docs:generate:jade', ->
    gulp.src(['docs/app/**/*.jade'])
      .pipe(jade())
      .pipe(gulp.dest('build/docs'))


  gulp.task 'docs:generate:coffee', ->
    gulp.src(['docs/app/src/**/*.coffee'])
      .pipe(coffee({bare: true}))
      .pipe(concat('application.js'))
      .pipe(gulp.dest('build/docs/scripts'))


  gulp.task 'docs:generate:scss', ->
    gulp.src(['docs/app/src/**/*.scss'])
      .pipe(scss())
      .pipe(concat('application.css'))
      .pipe(gulp.dest('build/docs/styles'))


  gulp.task 'docs:generate:dgeni', ->
    try
      dgeni = new Dgeni [require('../docs/config')]
      dgeni.generate();
    catch e
      throw e


  gulp.task 'docs:webserver:start', ->
    gulp.src("build/docs").pipe webserver
      livereload: true
    return