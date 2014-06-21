fs           = require 'fs'
gulp         = require 'gulp'
growler      = require 'growler'

class Growl
  initialize: ->
    @_lastSpecError = false

    if process.env.CI
      @_growl =
        sendNotification: ->

    else
      @_growl = new growler.GrowlApplication 'eventric'
      @_growl.setNotifications
        'Eventric': {}
      @_growl.register()


  showNotification: (text) =>
    @_growl.sendNotification 'Eventric',
      title: 'Gulp'
      text: text


  specsRun: =>
    @_specError = false


  specsError: (err) =>
    @_specError = err


  specsEnd: =>
    if @_specError
      @showNotification @_specError.message
      @_lastSpecError = true

    else
      if @_lastSpecError
        @showNotification 'Specs fixed'
      else
        @showNotification 'Specs passed'
      @_lastSpecError = false


module.exports = new Growl
