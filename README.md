# Dockerized EventSwarm kafka processor 

This is a simple JRuby Sinatra application that creates Kafka Stream instances that 
process JSON from a kafka topic using EventSwarm and publish EventSwarm matches 
as JSON on another kafka topic. Non-json data will cause an exception but will be ignored.

The app has been dockerized so that it can be easily deployed using docker-compose or 
kubernetes.

## Deployment

```
$ docker pull drpump/kafka-processor
$ docker run -it -p 4567:4567 -e KAFKA_BROKER="<kafka-broker>:<kafka-port>" "drpump/kafka-processor"
```

## Usage

### Quick check:

```
$ curl http://localhost:4567/ping
```

Returns "pong".

### Get running streams:

To list all current streams as JSON:

```
$ curl http://localhost:4567/streams
```

To retrieve details of a specific stream as JSON:

```
$ curl http://localhost:4567/stream/<stream-id>
```


### Create a new stream

To create an instance of a simple always-true expression, use:

```
$ curl -d '' 'http://localhost:4567/true?input=<input-topic>&output=<output-topic>'
```

You can alternatively pass the input and output topics as JSON, so:

```
$ curl -d '{"input":"<input-topic>", "output":"<output-topic>"}' 'http://localhost:4567/true'
```

To create an instance of an expression defined in the `rules/` directory, use (for example):

```
$ curl -d '{"input":"<input-topic>", "output":"<output-topic>"}' 'http://localhost:4567/stream/two_true'
```

You can replace `two_true` with the basename of your preferred expression (i.e. filename excluding the `.rb`) .

### Remove a stream

```
$ curl -X DELETE http://localhost:4567/stream/<stream-id>
```

## Add new EventSwarm expressions

### By mounting a rules directory

This is the simplest approach. Steps:

1. Create your own rules directory say `~/my_rules`
2. Mount this directory over the default `rules/` directory in the docker container, so:
    ```
    $ docker run -it -p 4567:4567 -e KAFKA_BROKER="192.168.1.30:9092" \
      --mount type=bind,source=$HOME/my_rules,target=/usr/src/app/rules drpump/kafka-processor:latest
    ```
2. Checkout the source code `git clone git@bitbucket.org:drpump95/kafka-processor` 
2. Copy the example rules in `kafka-processor/rules/` to your `~/my_rules` directory
3. Choose an example as a template and rename the file and contained ruby class appropriately. 
   Ruby convention is lowercase with underscores for file name, then 
   camel case for class names, so `my_rule.rb` should define the class `MyRule`.
4. Code your expression to return a `Rule` object from the `create` method.
5. Create a stream using your new class:
    ```
    $ curl -d '{"input":"<input-topic>", "output":"<output-topic>"}' 'http://localhost:4567/stream/my_rule'
    ```


### By modifying the source

To work with the source you need to set up a JRuby 9.2 development environment. Steps:

1. Use `rvm` or `rbenv` to set up a JRuby 9.2 environment
2. Checkout: `git clone git@bitbucket.org:drpump95/kafka-processor` 
3. `cd kafka-processor`
3. Use `bundle install` to grab the Ruby dependencies
3. Use `jruby -S jbundle install` to grab the Java dependencies
4. In the `rules/` directory, copy one of the examples and rename the file and class appropriately (see above for naming convention).
5. Code your expression in this new class
6. Assuming you have a kafka instance running, run the app using `bundle exec jruby app.rb` to test your expression
7. If you want it dockerized, `docker build <your-image-name> .`

## Some notes about EventSwarm

### Key concepts

EventSwarm allows you to construct a directed graph of processing components that collect, collate and match patterns against a stream of events. 
Graphs are constructed using an [observer](https://en.wikipedia.org/wiki/Observer_pattern) pattern, with upstream components offering _triggers_, 
and downstream components registering _action(s)_ against those triggers. Triggers and actions are strongly typed, for example, an `AddEventTrigger` signals that a new event has been added. 

EventSwarm processing graphs are processed _depth first_, that is, actions against a trigger are called in order, and each action calls downstream
actions registered against its triggers and so on before returning. There are classes that allow you to control this through queues and threading (i.e. actions to put an event in a queue for subsequent processing in a different thread).

Other concepts:

| ---: | --- |
| Expression | a component or chain of components that catches events matching an event expression |
| ComplexExpression | an expression that matches multiple events (e.g. a sequence of matching events) | 
| Matcher | A boolean expression relating to a single event, e.g. field `X > 1`, used within an expression |
| EventSet | A set of events | 
| Window | A set of events that _slides_ in response to some trigger, e.g. clock tick, new event arrival etc. Windows are mostly either size or time based, so for example, last 100 events or last hour. These classes explicitly remove events from the window (i.e. you can listen for remove triggers) |
| Retriever | A class that knows how to extract data from your events, for example, extract the value of attribute `X` from a JSON-encoded event |
| Value | A wrapper class for values, including constant values, used for comparison with data extracted from events |
| PowerSet | A PowerSet partitions a stream of events into subsets. The subsets can overlap, although the most commonly used implementation, `HashPowerSet`, creates subsets by hashing a single key and thus does not support overlaps |

### Java sub-packages

| ---: | --- |
| top level | `Trigger` and `Action` interface definitions |
| events | classes relating to construction and interrogation of events. The top level directory defines interfaces, implementations are in `jdo` |
| eventset | Various event set and window implementations |
| expressions | Expression and matcher classes | 
| channels | Classes to get events into EventSwarm (e.g. http), not used for this application | 
| schedules | Classes for generating tick and other events to control time windows and other features (e.g. an event-driven clock) |


