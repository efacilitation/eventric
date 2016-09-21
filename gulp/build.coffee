runSequence = require 'run-sequence'
webpack = require 'webpack-stream'

module.exports = (gulp) ->

  gulp.task 'build', (done) ->
    runSequence 'build:release', done


  gulp.task 'build:release', ->
    webpackConfig = require('./webpack_config').getDefaultConfiguration()
    webpackConfig.output =
      libraryTarget: 'umd'
      library: 'eventric'
      filename: 'eventric.js'

    gulp.src ['src/eventric.entry.coffee']
    .pipe webpack webpackConfig
    .pipe gulp.dest 'dist/release'
