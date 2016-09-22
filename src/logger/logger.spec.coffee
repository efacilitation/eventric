describe 'Logger', ->

  logger = null

  beforeEach ->
    logger = require './'


  describe '#constructor', ->

    it 'should have the warn log level as default', ->
      sandbox.stub console, 'warn'
      sandbox.stub console, 'info'
      logger.warn 'Warning message'
      logger.info 'Info message'
      expect(console['warn']).to.have.been.called
      expect(console['info']).to.have.not.been.called


  describe '#setLogLevel', ->

    it 'should set the log level', ->
      sandbox.stub console, 'info'
      logger.info 'Info message'
      expect(console['info']).to.have.not.been.called
      logger.setLogLevel 'info'
      logger.info 'Info message'
      expect(console['info']).to.have.been.called


  describe '#error', ->

    it 'should log an error message', ->
      sandbox.stub console, 'error'
      logger.error 'Error message'
      expect(console['error']).to.have.been.calledWith 'Error message'


  describe '#warn', ->

    beforeEach ->
      logger.setLogLevel 'warn'
      sandbox.stub console, 'warn'


    it 'should log a warning message', ->
      logger.warn 'Warning message'
      expect(console['warn']).to.have.been.calledWith 'Warning message'


    it 'should not log a warning message if log level is lower', ->
      logger.setLogLevel 'error'
      logger.warn 'Warning message'
      expect(console['warn']).to.have.not.been.called


  describe '#info', ->

    beforeEach ->
      logger.setLogLevel 'info'
      sandbox.stub console, 'info'


    it 'should log a info message', ->
      logger.info 'Info message'
      expect(console['info']).to.have.been.calledWith 'Info message'


    it 'should not log a info message if log level is lower', ->
      logger.setLogLevel 'warn'
      logger.info 'Info message'
      expect(console['info']).to.have.not.been.called


  describe '#debug', ->

    beforeEach ->
      logger.setLogLevel 'debug'
      sandbox.stub console, 'log'


    it 'should log a debug message', ->
      logger.debug 'Debug message'
      expect(console['log']).to.have.been.calledWith 'Debug message'


    it 'should not log a debug message if log level is lower', ->
      logger.setLogLevel 'info'
      logger.debug 'Debug message'
      expect(console['log']).to.have.not.been.called
