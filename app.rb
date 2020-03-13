# app.rb

# include current directory in load path
$:.unshift(".").uniq!

require 'sinatra'
require 'java'
require 'jbundler'
require 'eventswarm-jar'
require 'log4j-jar'
require 'revs/log4_j_logger'
require 'rule'
require 'rule_processor'

java_import 'org.apache.kafka.streams.processor.AbstractProcessor'
java_import 'org.apache.kafka.streams.processor.ProcessorSupplier'
java_import 'org.apache.kafka.streams.Topology'
java_import 'org.apache.kafka.streams.StreamsConfig'
java_import 'org.apache.kafka.streams.KafkaStreams'
java_import 'org.apache.kafka.common.serialization.Serdes'
java_import 'java.util.Properties'
java_import 'com.eventswarm.expressions.TrueExpression'

# make sure we can connect from anywhere
set :bind, '0.0.0.0'

class Copier < AbstractProcessor  
  def process(key, value)
    context.forward(key,value)
  end
end

class BlockSupplier
  include ProcessorSupplier

  def initialize(&block)
    @creator = block
  end

  def get
    @creator.call
  end
end

def kafka_props
  @props ||= Properties.new.tap do |props|
    props.put(StreamsConfig::APPLICATION_ID_CONFIG, "my-jruby-app");
    props.put(StreamsConfig::BOOTSTRAP_SERVERS_CONFIG, ENV['KAFKA_BROKER'] || 'localhost:9092');
    props.put(StreamsConfig::DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
    props.put(StreamsConfig::DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
  end
end

def make_stream(params, supplier, name="RULE")
  topol = Topology.new
    .addSource("SOURCE", params[:input])
    .addProcessor(name, supplier, "SOURCE")
    .addSink("SINK", params[:output], name)
  str = KafkaStreams.new(topol, kafka_props)
  str.start
  "input: #{params[:input]}, output: #{params[:output]}, stream state: #{str.state}, topology: #{topol.describe}\n"
end

get '/ping' do
  "pong\n"
end

# copy records from input topic to output topic using simple copier
get '/copy' do
  supplier = BlockSupplier.new do 
    Copier.new
  end
  make_stream(params, supplier, "COPIER")
end

get '/true' do 
  supplier = BlockSupplier.new do
    expr = TrueExpression.new   # use an always true expression
    rule = Rule.new(expr, expr) # expression is both entry point and match trigger
    RuleProcessor.new(rule)
  end
  make_stream(params, supplier, "ALWAYS_TRUE")
end