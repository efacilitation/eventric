module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-commonjs-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-clean'

  # Configure a mochaTest task
  grunt.initConfig
    mochaTest:
      test:
        options:
          reporter: 'spec'
        src: [
          'spec/**/*_spec.coffee'
        ]

    karma:
      unit:
        configFile: 'karma.conf.coffee'

    # Configure watcher
    watch:
      client:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['karma', 'build']

      server:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest', 'build']

      hybrid:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest', 'karma', 'build']


    commonjs:
      modules:
        options:
          pathReplace: (path) ->
            path = path.replace 'src', 'eventric'
            path = path.replace 'node_modules/backbone/backbone', 'backbone'
            path = path.replace 'node_modules/underscore/underscore', 'underscore'
            path = path.replace 'node_modules/async/lib/async', 'async'

        cwd: '.'
        src: ['src/**/*.coffee'
              'node_modules/underscore/underscore.js'
              'node_modules/backbone/backbone.js'
              'node_modules/async/lib/async.js'
            ]
        dest: 'tmp/'

    coffee:
      compileWithMaps:
        options:
          sourceMap: true
        files:
          'dist/eventric.js': ['tmp/**/*.coffee']

    concat:
      dist:
        src: ['tmp/node_modules/**/*.js']
        dest: 'dist/vendor.js'

    clean: ['tmp']

  grunt.registerTask 'build', ['commonjs', 'coffee', 'clean']