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
$ curl -d '{"input":"<input-topic>", "output":"output-topic"}' 'http://localhost:4567/true'
```

To create an instance of an expression defined in the `rules/` directory, use (for example):

```
$ curl -d '{"input":"<input-topic>", "output":"output-topic"}' 'http://localhost:4567/stream/two_true'
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
    $ docker run -it -p 4567:4567 -e KAFKA_BROKER="192.168.1.30:9092" --mount type=bind,source=$HOME/my_rules,tar
    get=/usr/src/app/rules drpump/kafka-processor:latest
    ```
2. Copy one of the example rules in `rules/` to your directory
3. Rename the file and contained ruby class appropriately. Ruby 
   convention is lowercase with underscores for file name, then 
   camel case for class names, so `my_rule.rb` defines the class `MyRule`.
4. Code your expression and return a `Rule` object from the `create` method.
5. Create a stream using your new class:
    ```
    $ curl -d '{"input":"<input-topic>", "output":"output-topic"}' 'http://localhost:4567/stream/my_rule'
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

