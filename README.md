> Not released yet. This hint will disappear with version 0.1.0.


![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## eventric.js [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

Build web applications based on Domain-driven Design and Layered Architecture.

Runs on NodeJS and modern Browsers. Therefore it's easy to share code between Server and Client. Information regarding the API and more can be found in the [Wiki](https://github.com/efacilitation/eventric/wiki).


### Why?

It is an alternative to [MVC](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)+[CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) Frameworks where you put a lot of effort into defining your data structure and so often end up with an [anemic domain model](http://www.martinfowler.com/bliki/AnemicDomainModel.html) on larger projects.

### How?

Basically you define `queries` and `commands` on `BoundedContexts`. The `commands` can result in series of `DomainEvents` consisting of properties that changed inside affected `Aggregates`. These `DomainEvents` represent the state of your domain model. `DomainEvents` get either persisted directly into the `EventStore` or send over a `RemoteService` first. The `RemoteService` can also be used to execute `queries` and `commands` remotely. This makes eventric.js really useful for distributed applications.


## Philosophy

* Emphasize [Domain-driven design](https://www.goodreads.com/book/show/179133.Domain_Driven_Design), [Event-driven architecture](https://www.goodreads.com/book/show/12369902-event-centric) and [Task-based UIs](http://cqrs.wordpress.com/documents/task-based-ui).
* Put the the Domain Model in the very center of your Layered Architecture ([Onion](http://jeffreypalermo.com/blog/the-onion-architecture-part-1/) / [Hexagonal](http://alistair.cockburn.us/Hexagonal+architecture))
* Explicitly set boundaries for parts of your application ([BoundedContexts](https://en.wikipedia.org/wiki/Domain-driven_design#Bounded_context) / [MicroServices](http://martinfowler.com/articles/microservices.html))
* Separation of concerns using Commands and Queries ([CQRS](http://msdn.microsoft.com/en-us/library/jj554200.aspx))
* Capture all changes to your application state as a sequence of events ([EventSourcing](http://martinfowler.com/eaaDev/EventSourcing.html) / [DomainEvents](http://www.udidahan.com/2009/06/14/domain-events-salvation/))


## Quick Start

For this example we use `MongoDB`. So a prerequisite is to install it locally. If its up and running we need the `eventric` and `eventric-store-mongodb` npm packages.


```
npm install eventric
npm install eventric-store-mongodb
```


Initialize the Store and configure eventric to use it.

```javascript
eventric = require('eventric');

eventricMongoDbStore = require('eventric-store-mongodb');
eventricMongoDbStore.initialize(function() {
  eventric.set 'store', eventricMongoDbStore
})
```


### [Setup BoundedContext](https://github.com/efacilitation/eventric/wiki/eventric#eventricboundedcontext)

Having discussed the upcoming **TodoApp Project** with the Business-Experts and fellow Developers it got clear that we should start with a `BoundedContext` named `Collaboration`.

```javascript
collaborationContext = eventric.boundedContext({name: 'collaboration'})
```


### [Adding Aggregate](https://github.com/efacilitation/eventric/wiki/BoundedContext#addaggregate)

Now that we created the `collaborationContext` let's add our `Todo` Aggregate, consisting of a simple `changeDescription` method inside the AggregateRoot.

```javascript
collaborationContext.addAggregate('Todo', {
  root: function() {
    this.changeDescription = function(description) {
      this.description = description;
    }
  }
});

```
> Hint: values assigned to `this.` are automatically part of the generated `DomainEvent`


### [Adding Commands](https://github.com/efacilitation/eventric/wiki/BoundedContext#addcommand)

To actually work with the `BoundedContext` from the outside world we need `commands` and `queries`. Let's start by adding a simple `command` that will create an instance of our `Todo` Aggregate.

```javascript
collaborationContext.addCommand('createTodo', function(params, callback) {
  this.aggregate.create('Todo', callback);
});
```
> Hint: `this.aggregate` is dependency injected

It would be nice if we could change the description of the `Todo`, so let's add this `command` too.

```javascript
collaborationContext.addCommand('changeTodoDescription', function(params, callback) {
  this.aggregate.command('Todo', params.id, 'changeDescription', params.description, callback);
});
```
> Hint: If successful this will trigger a *Todo:changeDescription* `DomainEvent`


### [Adding Query](https://github.com/efacilitation/eventric/wiki/BoundedContext#addquery)

And last but not least we want the ability to `query` for a `Todo` by its id.

```javascript
collaborationContext.addQuery('getTodoById', function(params, callback) {
  this.repository('Todo').findById(params.id, callback);
});
```
> Hint: `this.repository` is dependency injected


### Executing [Commands](https://github.com/efacilitation/eventric/wiki/BoundedContext#command) and [Queries](https://github.com/efacilitation/eventric/wiki/BoundedContext#query)

Initialize the `collaborationContext`, create a `Todo`, change the description of it and finally query the description again.

```javascript
collaborationContext.initialize(function() {
  var todoId = null;
  collaborationContext.command({
    name: 'createTodo'
  }).then(function(todoId) {
    return collaborationContext.command({
      name: 'changeTodoDescription',
      params: {
        id: todoId,
        description: 'Do something'
      }
    })
  }).then(function(todoId) {
    return collaborationContext.query({
      name: 'getTodoById',
      params: {
        id: todoId
      }
    })
  }).then(function(readTodo) {
    console.log(readTodo.description)
  })

});
```
This will output `Do something`. Your `Todo` Aggregate is now persisted using EventSourcing.

Congratulations, you have successfully applied DDD (tactical+technical) and CQRS! :)


## Running Tests

To execute all (client+server) tests, use:

```shell
gulp spec
```

You can watch for file-changes with

```shell
NODE_ENV=workstation gulp watch
```


## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
