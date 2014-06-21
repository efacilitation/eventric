> Not released yet. This hint will disappear with version 0.1.0.


![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## eventric.js [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

Build JavaScript applications based on Events and Domain-driven Design.

Runs on NodeJS and modern Browsers. Therefore it's easy to share code between Server and Client. Information regarding the API and more can be found in the [Wiki](https://github.com/efacilitation/eventric/wiki).


### Why?

It is an alternative to [MVC](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)+[CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) Frameworks where you put a lot of effort into defining your data structure and so often end up with an [anemic domain model](http://www.martinfowler.com/bliki/AnemicDomainModel.html) on larger projects.


## Features

* DDD BuildingBlocks
  * BoundedContext
  * DomainEvent
  * Aggregate

* CQRS
  * Persistent ReadModels and ProcessManagers
  * Support for Occasionally Connected Applications

* EventSourcing
  * Automated saving and applying of DomainEvents
  * Multiple Store Adapters


## Philosophy

* Emphasize [Domain-driven design](https://www.goodreads.com/book/show/179133.Domain_Driven_Design), [Event-driven architecture](https://www.goodreads.com/book/show/12369902-event-centric) and [Task-based UIs](http://cqrs.wordpress.com/documents/task-based-ui).
* Put the the Domain Model in the very center of your Layered Architecture ([Onion](http://jeffreypalermo.com/blog/the-onion-architecture-part-1/) / [Hexagonal](http://alistair.cockburn.us/Hexagonal+architecture))
* Explicitly set boundaries for parts of your application ([BoundedContexts](https://en.wikipedia.org/wiki/Domain-driven_design#Bounded_context) / [MicroServices](http://martinfowler.com/articles/microservices.html))
* Separation of concerns using Commands and Queries ([CQRS](http://msdn.microsoft.com/en-us/library/jj554200.aspx))
* Capture all changes to your application state as a sequence of events ([EventSourcing](http://martinfowler.com/eaaDev/EventSourcing.html) / [DomainEvents](http://www.udidahan.com/2009/06/14/domain-events-salvation/))


## A Note on DDD

Please keep in mind that eventric.js supplies you only with a structure that has common-sense in the DDD+CQRS community. But you really should get to know the tactical side of DDD as well, which is at least as important (and fun!) as the technical BuildingBlocks. When you dive into the topic you will quickly learn that the BoundedContext is mostly refered to as a tactical pattern. We decided to make it a technical pattern too because we think that it will help grasp the concept.


## Getting started

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
  eventric.set('store', eventricMongoDbStore);
});
```


### [Setup BoundedContext](https://github.com/efacilitation/eventric/wiki/eventric#eventricboundedcontext)

Having discussed the upcoming **TodoApp Project** with the Business-Experts and fellow Developers it got clear that we should start with a `BoundedContext` named `Collaboration`.

```javascript
collaboration = eventric.boundedContext({name: 'collaboration'})
```

### [Define the Event]()

Inside of our `Collaboration` Context things will happen which are called DomainEvents. A technique to come up with these is called [EventStorming](http://ziobrando.blogspot.co.uk/2013/11/introducing-event-storming.html). Lets add one called `TodoDescriptionChanged`.

```javascript
collaboration.addDomainEvent('TodoDescriptionChanged', function(params) {
  this.description = params.description;
})
```


### [Adding an Aggregate](https://github.com/efacilitation/eventric/wiki/BoundedContext#addaggregate)

Now we need an Aggregate which actually raises this DomainEvent and is able to handle it. Lets add it.

```javascript
collaboration.addAggregate('Todo', function() {
  this.changeDescription = function(description) {
    this.$raiseDomainEvent('TodoDescriptionChanged', {description: description})
  }
  this.handleTodoDescriptionChanged = function(domainEvent) {
    this.description = domainEvent.payload.description;
  }
});

```
> Hint: `this.$raiseDomainEvent` is dependency injected and the handle method is called by naming convention after raising.


### [Adding CommandHandlers](https://github.com/efacilitation/eventric/wiki/BoundedContext#addcommand)

To actually work with the `BoundedContext` from the outside world we need `CommandHandlers`. Let's start by adding a simple one that will create an instance of our `Todo` Aggregate.

```javascript
collaboration.addCommandHandler('createTodo', function(params, callback) {
  this.$aggregate.create({
    name: 'Todo'
  }).then(function(aggregateId){
    callback(null, aggregateId);
  })
});
```
> Hint: `this.$aggregate` is dependency injected

It would be nice if we could change the description of the `Todo`, so let's add this `CommandHandler` too.

```javascript
collaboration.addCommandHandler('changeTodoDescription', function(params, callback) {
  this.$aggregate.command({
    name: 'Todo',
    id: params.id,
    methodName: 'changeDescription',
    methodParams: [params.description]
  }).then(function() {
    callback(null, null);
  });
});
```


### [Adding a DomainEventHandler](https://github.com/efacilitation/eventric/wiki/BoundedContext#adddomaineventhandler)

And last but not least we want to console.log when the description of the `Todo` changes.

```javascript
collaboration.addDomainEventHandler('TodoDescriptionChanged', function(domainEvent) {
  console.log(domainEvent.payload.description);
});
```


### Executing [Commands](https://github.com/efacilitation/eventric/wiki/BoundedContext#command)

Initialize the Context, create a `Todo` and tell the `Todo` to change its description.

```javascript
var todoId = null;
collaboration.initialize(function() {

  collaboration.command({
    name: 'createTodo'
  }).then(function(todoId) {
    return collaboration.command({
      name: 'changeTodoDescription',
      params: {
        id: todoId,
        description: 'Do something'
      }
    })
  });

});
```
After executing the Commands the DomainEventHandler will print `Do something`. Your `Todo` Aggregate is now persisted using EventSourcing.

Congratulations, you have successfully applied DDD and CQRS! :)


## Running Tests

To execute all (client+server) tests, use:

```shell
gulp spec
```

You can watch for file-changes with

```shell
gulp watch
```


## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
