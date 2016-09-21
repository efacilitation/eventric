gulp  = require 'gulp'
gutil = require 'gulp-util'

gulp.on 'err', ->
gulp.on 'task_err', (error) ->
  if process.env.CI
    gutil.log error
    process.exit 1

require('./gulp/watch')(gulp)
require('./gulp/symlink')(gulp)
require('./gulp/specs')(gulp)
require('./gulp/lint')(gulp)
require('./gulp/build')(gulp)
