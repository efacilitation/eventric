![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

# eventric.js [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

Minimalist JavaScript framework to build applications based on DDD, CQRS and Event Sourcing.
Supports (micro)service based architectures and focuses on high [testability](https://github.com/efacilitation/eventric-testing).

eventric is written in CoffeeScript. If you need a JavaScript tutorial please compile the snippets below yourself.

### Current road map

Currently there is an event store implementation for MongoDB which **will not work correctly in a multi process scenario.**
We will soon be working on an event store implementation for
[http://geteventstore.com](http://geteventstore.com) which will get rid of this limitation.

Implementations for other databases are currently not planned.

## Tutorial

This tutorial will guide you through all features of eventric by implementing a simplified Todo application.

There is no API documentation. If you want to dig deeper, have a look at the source code and the specs.

### Installation

Install the framework inside your application with `npm install eventric`.

eventric requires [Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).
If you have to support older browsers install and use a polyfill, such as
[es6-promise](https://github.com/jakearchibald/es6-promise) or [rsvp.js](https://github.com/tildeio/rsvp.js).

### Context

First create a Todo context inside your application.

```coffeescript
todoContext = eventric.context 'Todo'
```

Contexts create architectural boundaries inside an eventric based application.
They can be compared to (micro)services and somewhat also to bounded contexts from an implementation perspective.

A context holds its own event store and provides a self contained space for domain events, aggregates, command and query handlers, projections and an event publishing infrastructure (which may be outsourced soon).

### Domain events

After creating the context the necessary domain events can be defined.

```coffeescript
todoContext.defineDomainEvents
  TodoCreated: ({title}) ->
    @title = title

  TodoTitleChanged: ({title}) ->
    @title = title

  TodoFinished: ->

```

Domain event definitions in eventric consist of two parts: The domain event name and the payload constructor function.
This definition is similar to a class used in statically typed languages such as Java or C#.
Inside the payload constructor function the expected values must be assigned to members of `this`.

*Note:* It is best practice to use the same name for parameters and assigned member variables.


### Aggregates

Domain events in eventric can only be emitted from inside aggregate instances.
An aggregate is defined through a plain class which must at least implement a `create()` function.
This function will be automatically called when creating a new aggregate from inside a command handler.

Use the injected function `$emitDomainEvent(eventName, eventPayload)` to emit a new domain event.
This will cause two things to happen:
- The new domain event is saved in the list of new domain events
- If existing, the correct handle function on the aggregate is executed (`handle<event name>()`)

The above mentioned handle functions are also used when loading and rebuilding an aggregate to create the current state.

```coffeescript
todoContext.addAggregate 'Todo', class Todo

  create: ({title}) ->
    if not title
      throw new Error 'title missing'
    @$emitDomainEvent 'TodoCreated',
      title: title


  changeTitle: ({title}) ->
    if not title
      throw new Error 'title missing'
    if @isFinished
      throw new Error 'todo already finished'

    @$emitDomainEvent 'TodoTitleChanged',
      title: title


  finish: ->
    @$emitDomainEvent 'TodoFinished'


  handleTodoFinished: ->
    @isFinished = true


```

*Note:* Aggregate functions (except for handle functions) can return promises. eventric will wait for them to resolve.


## Command handlers

Command handlers define the write side of the application service layer inside a context.

### Definition

Command handlers are registered by passing an object to the context where the keys define the command names.

```coffeescript
todoContext.addCommandHandlers

  CreateTodo: ({title}) ->
    @$aggregate.create 'Todo',
      title: title
    .then (todo) ->
      todo.$save()


  ChangeTodoTitle: ({todoId, title}) ->
    @$aggregate.load 'Todo', todoId
    .then (todo) ->
      todo.changeTitle title: title
      todo.$save()


  FinishTodo: ({todoId}) ->
    @$aggregate.load 'Todo', todoId
    .then (todo) ->
      todo.finish()
      todo.$save()


```

Use the injected service `$aggregate` to create, load, modify and save aggregate instances.
Creating an aggregate will cause the `create()` function defined on the aggregate class to be called.
Execute the injected function `$save()` to save new domain events and publish them via the event bus.

Although discouraged, queries can be executed by using the injected service `$query`.

### Execution

After defining the command handlers they can be executed from outside the context.
In order to work with a context it needs to be initialized.
The initialization is mainly required for projections.

```coffeescript
todoContext.initialize()
.then ->
  todoContext.command 'CreateTodo', title: 'My first todo'
.then (todoId) ->
  todoContext.command 'ChangeTodoTitle',
    todoId: todoId
    title: 'My first changed todo'
  .then ->
    todoContext.command 'FinishTodo',
      todoId: todoId
.then ->
  console.log 'todo created, changed and finished'
```


## Domain event handler

Domain event handlers can be registered for specific events and even for specific aggregate instances.

```coffeescript
todoContext.subscribeToDomainEvent 'TodoFinished', (domainEvent) ->
  console.log 'finished todo', domainEvent.aggregate.id

todoContext.subscribeToDomainEventWithAggregateId 'TodoTitleChanged', 'some aggregate id', (domainEvent) ->
  console.log 'change title to: ', domainEvent.payload.title
```

## Projections

Projections always replay an event stream from the beginning.
They are used to create or populate read models.

```coffeescript
todosReadModel = {}

todosProjection =

  initialize: (params, done) ->
    done()


  handleTodoCreated: (domainEvent) ->
    todosReadModel[domainEvent.aggregate.id] =
      title: domainEvent.payload.title


  handleTodoTitleChanged: (domainEvent) ->
    todosReadModel[domainEvent.aggregate.id].title = domainEvent.payload.title


  handleTodoFinished: (domainEvent) ->
    todosReadModel[domainEvent.aggregate.id].isFinished = true


todoContext.addProjection todosProjection


todoCountReadModel = 0

todoCountProjection =

  initialize: (params, done) ->
    done()


  handleTodoCreated: (domainEvent) ->
    todoCountReadModel++


todoContext.addProjection todoCountProjection
```

**Important:** Projections must be added to a context before it is initialized.


## Query handlers

Query handlers define the read side of the application service layer inside an eventric context.

### Definition

Query handlers are registered the same way command handlers are by passing an object to the context.

```coffeescript
todoContext.addQueryHandlers

  getTodoList: (params) ->
    return todosReadModel


  getTodoCount: (params) ->
    return todoCountReadModel
```

### Execution

Similar to command handlers queries can be executed from outside the context after defining them.

```coffeescript
todoContext.initialize()
.then ->
  todoContext.command 'CreateTodo', title: 'My first todo'
.then (todoId) ->
  todoContext.command 'ChangeTodoTitle',
    todoId: todoId
    title: 'My first changed todo'
  .then ->
    todoContext.command 'FinishTodo',
      todoId: todoId
.then ->
  todoContext.query 'getTodoList', {}
.then (todoList) ->
  console.log 'current todos:', todoList
  todoContext.query 'getTodoCount'
.then (todoCount) ->
  console.log 'current todo count:', todoCount
```

## Stores

The event store inside a context is responsible for saving domain events and searching them by aggregate id or event name.

### In memory

By default eventric uses an in memory event store which is mainly useful for demo applications and testing purposes.

### MongoDB

For actual applications use the mongodb event store to save domain events in a persistent way.
First, install it together with the mongodb module.

`npm install mongodb`
`npm install eventric-store-mongodb`

Then, before initializing any contexts, connect to the database and set the mongodb event store as eventric store.

```coffeescript
mongodb = require 'mongodb'
EventricMongoDBStore = require 'eventric-store-mongodb'

mongodb.MongoClient.connect 'your db url', (error, database) ->
  eventric.setStore EventricMongoDBStore, dbInstance: database

  # initialize todo context
```

## Persistent read models

An event store inside a context only handles domain event persistence (write side of the application).
Saving persistent read models (or views) are not scope of the eventric framework.

To illustrate how this can be done the above todo list projection is rewritten to use mongodb as read model store.

```
todoListProjection =

  initialize: (params, done) ->
    database.dropCollection 'todos'
    .then ->
      database.collection 'todos'
    .then (collection) ->
      @collection = collection
      done()


  handleTodoCreated: (domainEvent) ->
    @collection.insert
      id: domainEvent.aggregate.id
      title: domainEvent.payload.title


  handleTodoTitleChanged: (domainEvent) ->
    @collection.update id: domainEvent.aggregate.id,
      $set: title: domainEvent.payload.title


  handleTodoFinished: (domainEvent) ->
    @collection.update id: domainEvent.aggregate.id,
      $set: isFinished: true


```

*Note:* The above will cause the read model to be emptied whenever the process is restarted. Consider this a best practice.

The query handler can be changed accordingly to directly access the mongodb collection.

```coffeescript
todoContext.addQueryHandlers

  getTodos: ->
    database.collection 'todos'
    .then (collection) ->
      collection.find({}).toArray()


```

## Remotes

eventric supports service oriented architectures.
Consider every context to be a possible standalone (micro)service.
All contexts share the same API: commands, queries, domain event handlers and projections.

Use the `Remote` interface in order to communicate between contexts.


### In memory

By default eventric provides an in memory remote which is useful for in-process communication and testing purposes.

```coffeescript
todoContext = eventric.remote 'Todo'
todoContext.command 'CreateTodo'
.then (todoId) ->
  console.log todoId
```

### Socket.IO

All previous examples were meant to be executed in a single process on the server side of an application.
In order to communicate with a context running on a server from a browser use the Socket.IO remote implementations.

First, install the modules together with Socket.IO.

```
npm install socket.io
npm install eventric-remote-socketio-endpoint
npm install eventric-remote-socketio-client
```

Then, configure eventric on the server side to use Socket.IO as additional remote endpoint.

```coffeescript
socketIO = require 'socket.io'
socketIORemoteEndpoint  = require 'eventric-remote-socketio-endpoint'

io = socketIO.listen 1234
socketIORemoteEndpointOptions =
  ioInstance: io
socketIORemoteEndpoint.initialize socketIORemoteEndpointOptions, ->
  eventric.addRemoteEndpoint socketIORemoteEndpoint
```

Finally, include the Socket.IO client and eventric in an html file, configure the remote client and create a remote.

```html
<!DOCTYPE html>
<html>
  <head>
    <title>eventric tutorial</title>
  </head>
  <body>
    <!-- fix paths to files -->
    <script type="text/javascript" src="node_modules/socket.io/node_modules/socket.io-client/socket.io.js" ></script>
    <script type="text/javascript" src="node_modules/eventric/dist/release/eventric.js" ></script>
    <script type="text/javascript" src="node_modules/eventric-remote-socketio-client/dist/release/eventric_remote_socketio_client.js" ></script>

    <script type="text/javascript">
      var socket = io.connect('http://localhost:1234');
      socketIORemoteClient = window['eventric-remote-socketio-client'];
      socketIORemoteClient.initialize({
        ioClientInstance: socket
      })
      .then(function() {
        var todoContext = eventric.remote('Todo');
        todoContext.setClient(socketIORemoteClient);

        todoContext.command('CreateTodo', {title: 'My first todo'})
        .then(function(todoId) {
          console.log('Todo created: ', todoId);
        })
        .catch(function(error) {
          console.error('Error creating todo: ', error);
        });
      });
    </script>
  </body>
</html>
```

*Note:* Socket.IO remotes are not limited to browser to server. They can easily be used for server to server communication.


### Remote projections

One major strength of eventric is the possibility to create remote projections (or client side projections).
This feature makes it easily possible to create reactive user interfaces in the browser.

```coffeescript
todoContext = eventric.remote 'Todo'
todoContext.setClient socketIORemoteClient
todoProjection =

  initialize: (params, done) ->
    document.querySelector('body').innerHTML = '<h1>Todos</h1><div class="todos"></div>';
    done()


  handleTodoCreated: (domainEvent) ->
    todoElement = document.createElement 'div'
    todoElement.setAttribute 'id', domainEvent.aggregate.id
    todoElement.innerHTML = domainEvent.payload.title
    document.querySelector('.todos').appendChild todoElement


  handleTodoTitleChanged: (domainEvent) ->
    document.querySelector("[id='#{domainEvent.aggregate.id}']").innerHTML = domainEvent.payload.title


  handleTodoFinished: (domainEvent) ->
    document.querySelector("[id='#{domainEvent.aggregate.id}']").setAttribute 'style', 'text-decoration: line-through'


todoContext.initializeProjection todoProjection, {}
```

*Note:* `initializeProjection()` may be renamed to `addProjection()` in order to stay consistent with the context API.

## License

MIT

Copyright (c) 2013-2016 SixSteps Team, efa GmbH
