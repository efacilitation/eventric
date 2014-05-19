![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## Introduction [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

**eventric.js** is a JavaScript Framework (written in CoffeeScript) which helps developers to build flexible, maintainable, long-lasting web applications. It aims to be an alternative to CRUD-style Frameworks where you put a lot of effort into defining how your data structure has to look like. With **eventric.js** you concentrate on the **behaviour** of your business and built your application on it.

Informations regarding the Building Blocks, Best Practices, API and more can be found in the [Wiki](https://github.com/efacilitation/eventric/wiki).


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
coffeegulp spec
```

You can watch for file-changes with

```shell
NODE_ENV=workstation coffeegulp watch
```


## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
