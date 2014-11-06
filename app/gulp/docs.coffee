gulp            = require 'gulp'
Dgeni           = require 'dgeni'
runSequence     = require 'run-sequence'
coffee          = require 'gulp-coffee'
jade            = require 'gulp-jade'
path            = require 'canonical-path'
webserver       = require 'gulp-webserver'
gutil           = require 'gulp-util'
scss            = require 'gulp-sass'
concat          = require 'gulp-concat'
commonjsWrap    = require 'gulp-wrap-commonjs'
filter          = require 'gulp-filter'
templateCache   = require 'gulp-angular-templatecache'
mainBowerFiles  = require 'main-bower-files'

module.exports = (gulp) ->

  outputFolder = 'build/docs'
  bowerFolder = 'bower_components'

  copyComponent = (component, pattern, sourceFolder) ->
    pattern = pattern or "/**/*"
    sourceFolder = sourceFolder or bowerFolder
    gulp.src(sourceFolder + "/" + component + pattern)
    .pipe commonjsWrap
      pathModifier: (filePath) ->
        matches = filePath.match /(bower_components|node_modules)\/(.*?)\//
        moduleName = matches[2]
        moduleName

    .pipe gulp.dest(outputFolder + "/components/" + component)


  gulp.task 'docs:build', (next) ->
    runSequence 'docs:generate:dgeni', 'docs:generate:jade', 'docs:generate:coffee',
                'docs:generate:scss', 'docs:build:bower', 'docs:build:src', 'docs:webserver:start', 'docs:copy:eventric',
                'docs:generate:templatecache', 'spec:client:helper', next


  filterByExtension = (extension) ->
    filter (file) ->
      file.path.match new RegExp("." + extension + "$")


  gulp.task 'docs:build:src', ->
    gulp.src(['../index.coffee', '../+(src)/**/*.coffee'])
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/node'))


  gulp.task "docs:build:bower", ->
    mainFiles = mainBowerFiles
      includeDev: true
    return unless mainFiles.length

    gulp.src mainFiles
    .pipe filterByExtension("js")
    .pipe commonjsWrap
      pathModifier: (filePath) ->
        matches = filePath.match /(bower_components|node_modules)\/(.*?)\//
        moduleName = matches[2]
        moduleName
    .pipe concat("vendor.js")
    .pipe gulp.dest("build/docs/scripts")


    gulp.src(mainFiles)
    .pipe filterByExtension("css")
    .pipe concat("vendor.css")
    .pipe gulp.dest("build/docs/styles")
    return


  gulp.task 'docs:watch', (next) ->
    gulp.run [
      "docs:build"
    ]

    gulp.watch [
      "src/**/*.jade"
    ], ['docs:generate:jade']

    gulp.watch [
      "src/**/!(*.spec)*.coffee"
    ], ['docs:generate:coffee']

    gulp.watch [
      "src/**/*.spec.coffee"
    ], ['spec:client:run']

    gulp.watch [
      "src/**/*.scss"
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
    copyComponent 'angular-mocks', '/*'


  gulp.task 'docs:copy:eventric', ->
    gulp.src('../build/dist/eventric.js')
    .pipe(gulp.dest('build/docs/scripts'))


  gulp.task 'docs:generate:jade', ->
    gulp.src(['src/**/*.jade'])
      .pipe(jade())
      .pipe(gulp.dest('build/docs'))


  gulp.task 'docs:generate:templatecache', ->
    gulp.src 'build/docs/**/*.html'
      .pipe(templateCache
        module: "eventric.app.templates"
        standalone: true
      )
      .pipe(commonjsWrap(
        pathModifier: ->
          "eventric-app/templates"
      ))
      .pipe(gulp.dest('build/docs/templatecache'))


  gulp.task 'docs:generate:coffee', ->
    gulp.src([
      'src/**/*.coffee'
      '!./**/*.spec.coffee'
      ])
      .pipe(coffee({bare: true}))
      .pipe commonjsWrap
        pathModifier: (filePath) ->
          filePath = filePath.replace process.cwd(), 'eventric-app'
          filePath = filePath.replace /.js$/, ''

      .pipe(concat('application.js'))
      .pipe(gulp.dest('build/docs/scripts'))


  gulp.task 'docs:generate:scss', ->
    gulp.src(['src/**/*.scss'])
      .pipe(scss())
      .pipe(concat('application.css'))
      .pipe(gulp.dest('build/docs/styles'))


  gulp.task 'docs:generate:dgeni', ->
    try
      dgeni = new Dgeni [require('../dgeni')]
      dgeni.generate();
    catch e
      throw e


  gulp.task 'docs:webserver:start', ->
    gulp.src("build/docs").pipe webserver
      livereload: true
    return


  gulp.task 'spec:client:helper', ->
    gulp.src([
      'node_modules/chai/chai.js'
      'node_modules/async/lib/async.js'
      'node_modules/mockery/mockery.js'
      'node_modules/sinon/lib/**/*.js'
      'node_modules/sinon-chai/lib/sinon-chai.js'
    ])
      .pipe(commonjsWrap(
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
      .pipe(concat('helper.js'))
      .pipe(gulp.dest('build/spec/'))


  gulp.task 'spec:client:run', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
