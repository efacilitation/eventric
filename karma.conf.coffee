module.exports = (config) ->
  config.set
    basePath: ''

    files: [
      'dist/specs/specs.js'
    ]

    port: 9876

    colors: yes

    logLevel: config.LOG_INFO

    autoWatch: no

    browsers: ['PhantomJS']

    singleRun: yes

    reporters: ['spec']

    frameworks: ['mocha']

    plugins: [
      'karma-mocha'
      'karma-phantomjs-launcher'
      'karma-spec-reporter'
    ]
