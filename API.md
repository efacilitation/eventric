## eventric

### API



#### set

Params:
- *key* { Object } - Available keys are: `store` Eventric Store Adapter

> Use as: set(key, value)
Configure settings for the `context`.



#### emitDomainEvent

Params:
- *domainEventName* { String } - Name of the DomainEvent
- *domainEventPayload* { Object } - payload for the DomainEvent

emit Domain Event in the context



#### defineDomainEvent

Params:
- *domainEventName* { String } - Name of the DomainEvent
- *DomainEventClass* { Function } - DomainEventClass

Adds a DomainEvent Class which will be used when emitting or handling DomainEvents inside of Aggregates, Projectionpr or ProcessManagers



#### addCommandHandler

Params:
- *commandName* { String } - Name of the command
- *commandFunction* { String } - Gets `this.aggregate` dependency injected
`this.aggregate.command(params)` Execute command on Aggregate
 * `params.name` Name of the Aggregate
 * `params.id` Id of the Aggregate
 * `params.methodName` MethodName inside the Aggregate
 * `params.methodParams` Array of params which the specified AggregateMethod will get as function signature using a [splat](http://stackoverflow.com/questions/6201657/what-does-splats-mean-in-the-coffeescript-tutorial)

`this.aggregate.create(params)` Execute command on Aggregate
 * `params.name` Name of the Aggregate to be created
 * `params.props` Initial properties so be set on the Aggregate or handed to the Aggregates create() method





#### addQueryHandler

Params:
- *queryHandler* { String } - Name of the query
- *queryFunction* { String } - Function to execute on query





#### addAggregate

Params:
- *aggregateName* { String } - Name of the Aggregate
- *aggregateDefinition* { String } - Definition containing root and entities

Use as: addAggregate(aggregateName, aggregateDefinition)

Add [Aggregates](https://github.com/efacilitation/eventric/wiki/BuildingBlocks#aggregateroot) to the `context`. It takes an AggregateDefinition as argument. The AggregateDefinition must at least consists of one AggregateRoot and can optionally have multiple named AggregateEntities. The Root and Entities itself are completely vanilla since eventric follows the philosophy that your DomainModel-Code should be technology-agnostic.



#### subscribeToDomainEvent

Params:
- *domainEventName* { String } - Name of the `DomainEvent`
- *Function* { Function } - which gets called with `domainEvent` as argument
- `domainEvent` Instance of [[DomainEvent]]

Use as: subscribeToDomainEvent(domainEventName, domainEventHandlerFunction)

Add handler function which gets called when a specific `DomainEvent` gets triggered



#### subscribeToDomainEventWithAggregateId







#### addDomainService

Params:
- *domainServiceName* { String } - Name of the `DomainService`
- *Function* { Function } - which gets called with params as argument

Use as: addDomainService(domainServiceName, domainServiceFunction)

Add function which gets called when called using $domainService



#### addAdapter

Params:
- *adapterName* { String } - Name of Adapter
- *Adapter* { Function } - Class

Use as: addAdapter(adapterName, AdapterClass)

Add adapter which get can be used inside of `CommandHandlers`



#### addProjection

Params:
- *projectionName* { string } - Name of the Projection
- *The* { Function } - Projection Class definition
- define `subscribeToDomainEvents` as Array of DomainEventName Strings
- define handle Funtions for DomainEvents by convention: "handleDomainEventName"

Add Projection that can subscribe to and handle DomainEvents



#### initialize



Use as: initialize()

Initializes the `context` after the `add*` Methods



#### getProjection

Params:
- *projectionName* { String } - Name of the Projection

Get a Projection Instance after initialize()



#### getAdapter

Params:
- *adapterName* { String } - Name of the Adapter

Get a Adapter Instance after initialize()



#### getDomainEvent

Params:
- *domainEventName* { String } - Name of the DomainEvent

Get a DomainEvent Class after initialize()



#### getDomainService

Params:
- *domainServiceName* { String } - Name of the DomainService

Get a DomainService after initialize()



#### getDomainEventsStore



Get the DomainEventsStore after initialization



#### getEventBus



Get the EventBus after initialization



#### command

Params:
- *`commandName`* { String } - Name of the CommandHandler to be executed
- *`commandParams`* { Object } - Parameters for the CommandHandler function
- *callback* { Function } - Gets called after the command got executed with the arguments:
- `err` null if successful
- `result` Set by the `command`

Use as: command(command, callback)

Execute previously added `commands`



#### query

Params:
- *`queryName`* { String } - Name of the QueryHandler to be executed
- *`queryParams`* { Object } - Parameters for the QueryHandler function
- *`callback`* { Function } - Callback which gets called after query
- `err` null if successful
- `result` Set by the `query`

Use as: query(query, callback)

Execute previously added `QueryHandler`



#### 

Params:
- *name* { String } - Name of the context

Get a new context instance.



#### 

Params:
- *contextName* { String } - Name of the context or 'all'
- *eventName* { String } - Name of the Event or 'all'
- *eventHandler* { Function } - Function which handles the DomainEvent

Global DomainEvent Handlers



#### 

Params:
- *processManagerName* { String } - Name of the ProcessManager
- *processManagerObject* { Object } - Object containing `initializeWhen` and `class`

Global Process Manager



#### 

Params:
- *processManagerName* { String } - Name of the ProcessManager
- *processManagerObject* { Object } - Object containing `initializeWhen` and `class`

Process Manager




