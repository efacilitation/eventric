> Not released yet. This hint will disappear with version 0.1.0.


![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## Introduction [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

**eventric.js** is a JavaScript Framework (written in CoffeeScript) which helps developers to build flexible, maintainable, long-lasting web applications. It aims to be an alternative to MVC+CRUD-style Frameworks where you put a lot of effort into defining how your data structure has to look like. With **eventric.js** you concentrate instead on the **behaviour** of your business and built your application on it.

Basically you build a well defined, behavioural API using `commands` and `queries`. Executing a `command` will in turn act on a registered `Aggregate` (think of it as a advanced Model). This finally results in a so-called `DomainEvent`. This series of `DomainEvents` defines the state of your `Aggregate` and therefore of your application.

**eventric.js** will run on NodeJS as well as in the Browser. Depending on the scenario you can persist the `DomainEvents` directly into the eventric EventStore or send it over some `RemoteService` first. The `RemoteService` can also be used to access your API remotely. This makes **eventric.js** really useful for distributed applications.

Information regarding the API and more can be found in the [Wiki](https://github.com/efacilitation/eventric/wiki).


## Quick Start

```shell
npm install eventric
```

For a brief overview on how to use eventric check out this example:

* [TodoApp Example](https://github.com/efacilitation/eventric/wiki/ExampleTodo)


## Philosophy

* Emphasize [Domain-driven design](https://www.goodreads.com/book/show/179133.Domain_Driven_Design), [Event-driven architecture](https://www.goodreads.com/book/show/12369902-event-centric) and [Task-based UIs](http://cqrs.wordpress.com/documents/task-based-ui).
* Explicitly set boundaries for parts of your application ([BoundedContexts](https://en.wikipedia.org/wiki/Domain-driven_design#Bounded_context) / [MicroServices](http://martinfowler.com/articles/microservices.html))
* Separation of concerns using Commands and Queries ([CQRS](http://msdn.microsoft.com/en-us/library/jj554200.aspx))
* Capture all changes to your application state as a sequence of events ([EventSourcing](http://martinfowler.com/eaaDev/EventSourcing.html) / [DomainEvents](http://www.udidahan.com/2009/06/14/domain-events-salvation/))


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
