# Todo App Example

## Setup

### Aggregate

So we want to implement some simple Todo App. First we need a `Aggregate` for our `Todo`

```
class Todo extends eventric.AggregateRoot
```

Our `Aggregate` will be responsible for `command`-handling. Lets add some commands

```
  updateTitle: (title) ->
    @_set 'title' = title


  updateCompleted: (completed) ->
    @_set 'completed' = completed
```

 Having some default values for our `Todo` upon construction might be handy, so lets do this by adding a `constructor`

```
  constructor: (title) ->
    @updateTitle title
    @updateCompleted false
```


### ReadAggregate

The `ReadAggregate` will handle all queries that we might need, e.g. `getTitle` or `isCompleted`

```
class ReadTodo extends eventric.ReadAggregateRoot
  getTitle: ->
    @_get 'title'

  isCompleted: ->
    @_get 'completed'
```


### BoundedContext

The public interface for our Todo App will be accessible through a `BoundedContext`

```
class TodosContext extends eventric.BoundedContext
  aggregates:
    'Todo': Todo
```


## Usage

To get it all running we first initialize our TodoApp BoundedContext

```
todoContext = new TodosContext
```

Now we're ready. Lets create a Todo

```
todoId = todoContext.command 'Todo:create', 'Temporary title'
```

Change the Title and updated the completed-status

```
todoContext.command 'Todo:updateTitle', todoId, 'There is something to do!'
todoContext.command 'Todo:updateCompleted', todoId, true
```

Get all Todos

```
todos = todoContext.query 'Todo:find'
```

and output their title and completed-status

```
for todo in todos
  console.log "#{todo.getTitle()} -- completed: #{todo.isCompleted()}"
```

This will output

```
There is something to do! -- completed: true
```

---

# Aggregate

> A collection of objects that are bound together by a root entity, otherwise known as an aggregate root. The aggregate root guarantees the consistency of changes being made within the aggregate by forbidding external objects from holding references to its members. [[Wikipedia](https://en.wikipedia.org/wiki/Domain-driven_design#Building_blocks_of_DDD)]
> *Example: When you drive a car, you do not have to worry about moving the wheels forward, making the engine combust with spark and fuel, etc.; you are simply driving the car. In this context, the car is an aggregate of several other objects and serves as the aggregate root to all of the other systems.*

## AggregateRoot

- Stellt Interface "nach außen" / "zur Command-Schicht"
- extends AggregateEntity

## AggregateEntity

> An object that is not defined by its attributes, but rather by a thread of continuity and its identity. [[Wikipedia](https://en.wikipedia.org/wiki/Domain-driven_design#Building_blocks_of_DDD)]
> *Example: Most airlines distinguish each seat uniquely on every flight. Each seat is an entity in this context. However, Southwest Airlines (or EasyJet/RyanAir for Europeans) does not distinguish between every seat; all seats are the same. In this context, a seat is actually a value object.*

- Bildet das Write/Setter-Model ab
- Kann andere Entitys in Form von collections enthalten (Aggregate)
- Kann Referenzen auf andere AggregateRoots enthalten (ReadAggregate!)
- Ist nur für Write-Operationen zuständig
- Gibt keine Daten zurück / Hat keine getter-Funktionen

---

# ReadAggregate

> Place as much of the logic of the program as possible into functions, operations that return results with no observable side effects. Strictly segregate commands (methods that result in modifications to observable state) into very simple operations that do not return domain information. Further control side effects by moving complex logic into VALUE OBJECTS when a concept fitting the responsibility presents itself. [Evans, 2004]

> An operation that mixes logic or calculations with state change should be refactored into two separate operations (Fowler 1999, p. 279).

## ReadAggregateRoot

- Stellt Interface "nach außen" / "zur View/Query.Schicht"
- Wird von Events zu einem letztendlich konsistenten Zustand gebracht
- extends ReadAggregateEntity

## ReadAggregateEntity

- Bildet das Read/Query/Getter-Model ab
- Gibt Daten zurück / Bietet getter-Funktionen
- Darf nicht direkt "von außen" beschrieben werden

---

# AggregateData

Ein Baum bestehend aus EntityData

## EntityData

_props Hash

Aggregate kann schreibend darauf zugreifen.
ReadAggregate kann lesend darauf zugreifen.

---

# ReadMix (Denormalized)

- Kann mehrere ReadAggregate enthalten
- Kann Methoden bereitstellen um Daten von mehreren ReadAggregate zu mischen
- Kann intern eine "denormalisierte" Daten-Struktur basierend auf speziellen Domain-Event-Handlern aufbauen

---

# Service

> When a significant process or transformation in the domain is not a natural responsibility of an ENTITY or VALUE OBJECT, add an operation to the model as a standalone interface declared as a SERVICE. Define the interface in terms of the language of the model and make sure the operation name is part of the UBIQUITOUS LANGUAGE. Make the SERVICE stateless. [Evans, 2004]

- Konfiguriert sich selbst im Konstruktuor (Service-Zustand)
- Orchestriert Domain-Models, Repositories und andere Services
- Hat keinen Domain-Relevanten Zustand

---

# MixIns

- Funktionalitäten die sowohl in Enties als auch ReadModels benötigt werden
- Property Handling

---

# Repository

> A REPOSITORY represents all objects of a certain type as a conceptual set (usually emulated). It acts like a collection, except with more elaborate querying capability. Objects of the appropriate type are added and removed, and the machinery behind the REPOSITORY inserts them or deletes them from the database. This definition gathers a cohesive set of responsibilities for providing access to the roots of AGGREGATES from early life cycle through the end. [Evans, 2004]

- Abstrahiert die Persistenzschicht und kümmert sich um DataMapping
- Kann Aggregate und ReadModel zurückgeben
- Kann aktive Aggregate und ReadModel im Speicher halten
- Nutzt Adapter

---


## AggregatRepository


**Fetch By ID**


- Existiert ein aktives Aggregat im Speicher (In-Memory)?
  * Direkt zum Event-Store



- Existiert ein Aggregat-Snapshot?

  * Falls ja wird der aktuelle Snapshot zurückgegeben
  * Im Snapshot steht das zuletzt verarbeitete Event


- Existieren Events für die Aggregat ID?
  * Berücksichtigt das zuletzt verarbeitete Event



## ReadAggregateRepository


** Fetch By ID**

 - wie  beim Aggregat


**Fetch By Specification** (bspw fetchByDateRange)


Geht immer auf die Snapshots, da aktuell Queries auf den EventStore noch nicht möglich sind


- Holt sich die entsprechenden "Aggregat-Daten"
- Schaut anschließend für jeden involvierten Datensatz (anhand der ID) nach Events und applied entsprechend

---

[Architektur-Sketches](https://owncloud.sixsteps.com/public.php?service=files&t=05780e32e86fad474df8192a671da952)

# ValueObject

> An object that contains attributes but has no conceptual identity. They should be treated as immutable. [[Wikipedia](https://en.wikipedia.org/wiki/Domain-driven_design#Building_blocks_of_DDD)]
> *Example: When people exchange dollar bills, they generally do not distinguish between each unique bill; they only are concerned about the face value of the dollar bill. In this context, dollar bills are value objects. However, the Federal Reserve may be concerned about each unique bill; in this context each bill would be an entity.*

- Haben keine Identität (id)
- Können sowohl beim Write wie auch beim Read genutzt werden
- Können in verschiedenen Aggregaten genutzt werden

---

# Commands (Client/Server)

> Sagen dass etwas getan werden muss

**Commands die auf dem Client ausgeführt werden**

- können zuerst an den Server geschickt werden
- können sofort ein Update des DataModels auf dem Client bewirken
  * werden anschließend an den Server übertragen um dort noch mal ausgeführt zu werden

**Commands die auf dem Server ausgeführt werden**

- können feststellen ob Command erfolgreich ausgeführt werden kann (sollte überwiegend der fall sein) und den Client der das Command geschickt hat entsprechend ACK/NACKen
- können das generierte Event anschließend per Broadcast an andere Clients schicken (nicht immer)


## Commands Beispiele

**Karte verschieben**

- Benutzer verschiebt Karte in er UI
- UI löst das Command "karteVerschieben" aus
- DomainModel verarbeitet das Command sofort und aktualisiert das DataModel
  * Sammeln->karteVerschieben(parameter)
- Command wird implizit an den Server verschickt und dort nochmal ausgeführt


**Zahlung ausführen**

- Benutzer klickt in der UI auf "Zahlung ausführen"
- UI löst das Command "zahlungAusführen aus"
- Command wird direkt an den Server übertragen und nicht auf dem Client ausgeführt
  * ServerCommand->process("zahlungAusführen", parameter)


**Server Command erfolgreich**
- Client bekommt die Bestätigung, dass sein Command ausgeführt wurde mit den resultierenden Events
- Server generiert ein Event basierend auf dem Command und verteilt es u. U. an andere Clients

**Server Command fehlerhaft**
- Client bekommt die Nachricht, dass Command nicht ausgeführt wurde zusammen mit dem Zustand (Model) zu dem er zurückkehren soll


# Events

> Sagen dass etwas passiert ist


---

thoughts on data inside the aggregate:

only use primitives (string, number, boolean)
if you need objects or arrays, use entities or entitycollections!

this has multiple reasons, but foremost its because its really difficult to automatically include changes into the domainevent
maybe let _set check if you want to set object/array and then just tell you: sorry, not possible?


see also:
http://stackoverflow.com/questions/11661380/does-backbone-models-this-get-copy-an-entire-array-or-point-to-the-same-array

---

thoughts on repository:

Es ist notwendig, dass man alle Aggregate und ReadAggregate beim Repository registriert,
damit es dem Repository möglich ist basierend auf dem Namen die entsprechenden Instanzen
zu bauen!

    aggregateRepository.registerClass 'Passenger', Passenger

readAggregateRepository.registerClass 'ReadPassenger', ReadPassenger

aggregateRepository.findById 'Passenger', 1, ->

readAggregateRepository.find 'ReadPassenger', query, ->

Im Falle von spezialisierten ReadAggregateRepositories ist das Verhalten dann konsistent,
denn man kann bei diesen intern entsprechend im constructor die passende Klasse registrieren.


class ReadPassengerRepository extends Repository

  constructor: ->
    super
    @registerClass 'ReadPassenger', require('some-module')('ReadPassenger')

  findAllDelayedBy10MinutesAndMore: ->
    @_eventStore.find query, (err, result) ->
      ...


---


Alternative wäre, dass sich Read/Aggregate selbst bauen indem man ihnen einen EventStore/Repository
zur Verfügung stellt. Allerdings sollen Aggregate durch die CommandSchicht weggeschachtelt
werden. Damit wäre diese Anforderung verletzt

aggregate = new Aggregate eventStore

---

thoughts on event-structure:

# event data
name: 'create'
timestamp: '201401111747'

# aggregate data
aggregate:
  id: 1
  name: 'Train'
  changed:

    # properties
    props:
      trainName: 'ICE 3272'

    # one-to-one entity relation
    entities:
      lokfuehrer:
        id: _123
        name: 'Lokfuehrer'
        changed:
          props:
            name: 'Hans'

    # one-to-many entity relation
    collections:
      passengers: [
        id: _1
        name: 'Passenger'
        changed:
          props:
            seat: 'XYZ'
      ]


---

