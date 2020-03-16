# Dockerized kafka processor using EventSwarm

This is a simple JRuby Sinatra application that creates Kafka Stream instances that 
process JSON from a kafka topic using EventSwarm and publish EventSwarm matches 
as JSON on another kafka topic. 

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

To a list of all current streams as JSON:

```
$ curl http://localhost:4567/streams
```

To retrieve details of a specific stream as JSON:

```
$ curl http://localhost:4567/stream/<stream-id>
```


### Create a new stream

Currently only a single EventSwarm expression is implemented. It matches all events and copies them to the output topic. To create an instance, use:

```
$ curl -d '' 'http://localhost:4567/true?input=<input-topic>&output=<output-topic>'
```

You can alternatively pass the input and output topics as JSON, so:

```
$ curl -d '{"input":"<input-topic>", "output":"output-topic"}' 'http://localhost:4567/true'
```

### Remove a stream

```
$ curl -X DELETE http://localhost:4567/stream/<stream-id>
```

## Add new EventSwarm expressions

For now, you need to set up a JRuby 9.2 development environment and checkout/modify the source. Steps:

1. Use `rvm` or `rbenv` to set up a JRuby 9.2 environment
2. Use `bundle install` to grab the Ruby dependencies
3. Use `jruby -S jbundle install` to grab the Java dependencies
4. Review `app.rb` and the `/true` entry point in particular. This uses a Ruby block to create an EventSwarm expression, 
   creates a Kafka Streams `Supplier` for that expression, then creates a stream using that supplier. 
5. Copy the `/true` entry point code and create a new entry point in `app.rb` with a Ruby block for your expression. 
6. Assuming you have a kafka instance running, run the app using `bundle exec jruby app.rb` to test your expression
7. If you want it dockerized, `docker build <your-image-name> .`

In future it is likely that you will be able to mount a directory containing your expressions code on our docker image
and avoid setting up a JRuby environment. Watch this space!
