webpack = require 'webpack-stream'

module.exports = (gulp) ->
  gulp.task 'build', ->
    webpackConfig = require('./webpack_config').getDefaultConfiguration()
    webpackConfig.output =
      libraryTarget: 'umd'
      library: 'eventric'
      filename: 'eventric.js'

    gulp.src ['src/index.coffee']
    .pipe webpack webpackConfig
    .pipe gulp.dest 'dist/release'