# app.rb
require 'sinatra'
require 'java'
require 'jbundler'

java_import 'org.apache.kafka.streams.processor.AbstractProcessor'
java_import 'org.apache.kafka.streams.processor.ProcessorSupplier'
java_import 'org.apache.kafka.streams.Topology'
java_import 'org.apache.kafka.streams.StreamsConfig'
java_import 'org.apache.kafka.streams.KafkaStreams'
java_import 'java.util.Properties'

class Copier < AbstractProcessor  
  def process(key, value)
    context.forward(key,value)
  end
end

class CopierSupplier
  include ProcessorSupplier

  def get
    Copier.new
  end
end

def kafka_props
  @props ||= Properties.new.tap do |props|
    props.put(StreamsConfig::APPLICATION_ID_CONFIG, "my-jruby-app");
    props.put(StreamsConfig::BOOTSTRAP_SERVERS_CONFIG, "127.0.0.1:9092");
  end
end

get '/ping' do
  "pong\n"
end

# copy records from input topic to output topic using simple copier
get '/copy' do
  topol = Topology.new
    .addSource("SOURCE", params[:input])
    .addProcessor("COPIER", CopierSupplier.new, "SOURCE")
    .addSink("SINK", params[:output], "COPIER")
  stream = KafkaStreams.new(topol, kafka_props)
  stream.start
  "Copying from #{params[:input]} to #{params[:output]}, stream is in state #{stream.state} and topology is #{topol.describe}\n"
end
