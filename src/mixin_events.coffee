# MixinEvents
# ---------------

# A module that can be mixed in to *any object* in order to provide it with
# custom events. You may bind with `on` or remove with `off` callback
# functions to an event; `trigger`-ing an event fires all callbacks in
# succession.
#
#     var object = {};
#     _.extend(object, Backbone.Events);
#     object.on('expand', function(){ alert('expanded'); });
#     object.trigger('expand');
#

# Copyright (c) 2010-2014 Jeremy Ashkenas, DocumentCloud
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# https://github.com/jashkenas/backbone

eventric = require 'eventric'
_ = eventric 'HelperUnderscore'

Events = MixinEvents =

  # Bind an event to a `callback` function. Passing `"all"` will bind
  # the callback to all events fired.
  on: (name, callback, context) ->
    return this  if not eventsApi(this, "on", name, [
      callback
      context
    ]) or not callback
    @_events or (@_events = {})
    events = @_events[name] or (@_events[name] = [])
    events.push
      callback: callback
      context: context
      ctx: context or this

    this


  # Bind an event to only be triggered a single time. After the first time
  # the callback is invoked, it will be removed.
  once: (name, callback, context) ->
    return this  if not eventsApi(this, "once", name, [
      callback
      context
    ]) or not callback
    self = this
    once = _.once(->
      self.off name, once
      callback.apply this, arguments_
      return
    )
    once._callback = callback
    @on name, once, context


  # Remove one or many callbacks. If `context` is null, removes all
  # callbacks with that function. If `callback` is null, removes all
  # callbacks for the event. If `name` is null, removes all bound
  # callbacks for all events.
  off: (name, callback, context) ->
    retain = undefined
    ev = undefined
    events = undefined
    names = undefined
    i = undefined
    l = undefined
    j = undefined
    k = undefined
    return this  if not @_events or not eventsApi(this, "off", name, [
      callback
      context
    ])
    if not name and not callback and not context
      @_events = undefined
      return this
    names = (if name then [name] else _.keys(@_events))
    i = 0
    l = names.length

    while i < l
      name = names[i]
      if events = @_events[name]
        @_events[name] = retain = []
        if callback or context
          j = 0
          k = events.length

          while j < k
            ev = events[j]
            retain.push ev  if (callback and callback isnt ev.callback and callback isnt ev.callback._callback) or (context and context isnt ev.context)
            j++
        delete @_events[name]  unless retain.length
      i++
    this


  # Trigger one or many events, firing all bound callbacks. Callbacks are
  # passed the same arguments as `trigger` is, apart from the event name
  # (unless you're listening on `"all"`, which will cause your callback to
  # receive the true name of the event as the first argument).
  trigger: (name) ->
    return this  unless @_events
    args = slice.call(arguments_, 1)
    return this  unless eventsApi(this, "trigger", name, args)
    events = @_events[name]
    allEvents = @_events.all
    triggerEvents events, args  if events
    triggerEvents allEvents, arguments_  if allEvents
    this


  # Tell this object to stop listening to either specific events ... or
  # to every object it's currently listening to.
  stopListening: (obj, name, callback) ->
    listeningTo = @_listeningTo
    return this  unless listeningTo
    remove = not name and not callback
    callback = this  if not callback and typeof name is "object"
    (listeningTo = {})[obj._listenId] = obj  if obj
    for id of listeningTo
      obj = listeningTo[id]
      obj.off name, callback, this
      delete @_listeningTo[id]  if remove or _.isEmpty(obj._events)
    this


# Regular expression used to split event strings.
eventSplitter = /\s+/

# Implement fancy features of the Events API such as multiple event
# names `"change blur"` and jQuery-style event maps `{change: action}`
# in terms of the existing API.
eventsApi = (obj, action, name, rest) ->
  return true  unless name

  # Handle event maps.
  if typeof name is "object"
    for key of name
      obj[action].apply obj, [
        key
        name[key]
      ].concat(rest)
    return false

  # Handle space separated event names.
  if eventSplitter.test(name)
    names = name.split(eventSplitter)
    i = 0
    l = names.length

    while i < l
      obj[action].apply obj, [names[i]].concat(rest)
      i++
    return false
  true


# A difficult-to-believe, but optimized internal dispatch function for
# triggering events. Tries to keep the usual cases speedy (most internal
# Backbone events have 3 arguments).
triggerEvents = (events, args) ->
  ev = undefined
  i = -1
  l = events.length
  a1 = args[0]
  a2 = args[1]
  a3 = args[2]
  switch args.length
    when 0
      (ev = events[i]).callback.call ev.ctx  while ++i < l
      return
    when 1
      (ev = events[i]).callback.call ev.ctx, a1  while ++i < l
      return
    when 2
      (ev = events[i]).callback.call ev.ctx, a1, a2  while ++i < l
      return
    when 3
      (ev = events[i]).callback.call ev.ctx, a1, a2, a3  while ++i < l
      return
    else
      (ev = events[i]).callback.apply ev.ctx, args  while ++i < l
      return

listenMethods =
  listenTo: "on"
  listenToOnce: "once"


# Inversion-of-control versions of `on` and `once`. Tell *this* object to
# listen to an event in another object ... keeping track of what it's
# listening to.
_.each listenMethods, (implementation, method) ->
  Events[method] = (obj, name, callback) ->
    listeningTo = @_listeningTo or (@_listeningTo = {})
    id = obj._listenId or (obj._listenId = _.uniqueId("l"))
    listeningTo[id] = obj
    callback = this  if not callback and typeof name is "object"
    obj[implementation] name, callback, this
    this

  return


# Aliases for backwards compatibility.
Events.bind = Events.on
Events.unbind = Events.off

module.exports = MixinEvents
