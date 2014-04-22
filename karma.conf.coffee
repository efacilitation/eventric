# Karma configuration

module.exports = (config) ->
  config.set
    # base path, that will be used to resolve files and exclude
    basePath: ''

    # list of files / patterns to load in the browser
    files: [
      # -- commonjs loader --
      'node_modules/commonjs-require/commonjs-require.js'
      'node_modules/commonjs-require/node-module-emulator.js'

      # -- wrapped by commonjs --
      'node_modules/expect.js/expect.js'
      'node_modules/underscore/underscore.js'
      'node_modules/backbone/backbone.js'
      'node_modules/async/lib/async.js'
      'node_modules/mockery/mockery.js'
      'vendor/sinon.js'

      'index.coffee'
      'src/**/*.coffee'

      # -- not wrapped by commonjs and therefore directly executed --
      'spec/**/*_spec.coffee'
    ]

    # list of files to exclude
    exclude: [

    ]

    # compile coffee scripts and wrap into commonjs
    preprocessors:
      'index.coffee': ['commonjs', 'coffee']
      'src/**/*.coffee': ['commonjs', 'coffee']
      'spec/**/*.coffee': ['coffee']

      'node_modules/expect.js/expect.js': ['commonjs']
      'node_modules/underscore/underscore.js': ['commonjs']
      'node_modules/backbone/backbone.js': ['commonjs']
      'node_modules/async/lib/async.js': ['commonjs']
      'node_modules/mockery/mockery.js': ['commonjs']
      'vendor/sinon.js': ['commonjs']

    coffeePreprocessor:
      options:
        sourceMap: true

    commonjsPreprocessor:
      options:
        pathReplace: (path) ->
          newPath = path
          if (path.indexOf 'node_modules/expect.js') == 0
            # commonjs-preprocessor strips the extension, but the module is named 'expect.js' in node..
            newPath = 'expect.js.js'

          else if (path.indexOf 'node_modules/backbone') == 0
            newPath = 'backbone'

          else if (path.indexOf 'node_modules/underscore') == 0
            newPath = 'underscore'

          else if (path.indexOf 'node_modules/async') == 0
            newPath = 'async'

          else if (path.indexOf 'node_modules/mockery') == 0
            newPath = 'mockery'

          else if (path.indexOf 'vendor') == 0
            newPath = path.replace /^vendor\//, ''

          else
            newPath = "eventric/#{path}"

    # web server port
    port: 9876

    # enable / disable colors in the output (reporters and logs)
    colors: yes

    # level of logging
    # possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_INFO

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: no

    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari
    # - PhantomJS
    browsers: ['PhantomJS']

    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: yes

    reporters: ['spec']

    frameworks: ['mocha']

    plugins: [
      'karma-mocha'
      'karma-phantomjs-launcher'
      'karma-chrome-launcher'
      'karma-spec-reporter'
      'karma-coffee-preprocessor'
      'karma-commonjs-preprocessor'
    ]