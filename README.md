![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## Introduction [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

**eventric.js** is a JavaScript Framework (written in CoffeeScript) which helps developers to build flexible, maintainable, long-lasting web applications. It aims to be an alternative to CRUD-style Frameworks where you put a lot of effort into defining how your data structure has to look like. With **eventric.js** you concentrate on the **behaviour** of your business and built your application on it.

The **eventric.js** philosophy is to emphasize Domain-driven design, Event-driven architecture and Task-based UIs.


## Features

* BoundedContexts / MicroServices
* CQRS
* EventSourcing
* DomainEvents

More Informations in the [Wiki](https://github.com/efacilitation/eventric/wiki).


## Quick Start

For a brief overview on how to use eventric check out one of the following examples:

* [TodoApp Example](https://github.com/efacilitation/eventric/wiki/ExampleTodo)


## Running Tests

To execute all (client+server) tests, use:

```javascript
grunt spec
```

You can watch for file-changes with

```javascript
grunt watch:hybrid
```


## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
