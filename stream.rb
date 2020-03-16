require 'java'
require 'jbundler'
require 'hashids'

java_import 'org.apache.kafka.streams.KafkaStreams'
java_import 'org.apache.kafka.streams.Topology'
java_import 'org.apache.kafka.streams.StreamsConfig'
java_import 'org.apache.kafka.common.serialization.Serdes'
java_import 'java.util.Properties'


class Stream
  attr_reader :id, :kstream, :topology, :input, :output

  PROCESSOR='EVENTSWARM'

  class << self
    def hashids 
      @hashids ||= Hashids.new("add some salt")
    end
  end

  def initialize(input, output, supplier)
    @input = input
    @output = output
    @_supplier = supplier
    @id ||= self.class.hashids.encode(self.object_id)
  end

  def start
    @topology = Topology.new
      .addSource("SOURCE", @input)
      .addProcessor(PROCESSOR, @_supplier, "SOURCE")
      .addSink("SINK", @output, PROCESSOR)
    @stream = KafkaStreams.new(@topology, props)
    @stream.start
  end

  def close
    @stream.close
  end

  def to_h
    {id: @id, input: @input, output: @output, state: "#{@stream.state}", topology: "#{@topology.describe}"}
  end

  def describe
    "id: #{id}, input: #{@input}, output: #{@output}, stream state: #{@stream.state}, topology: #{@topology.describe}"
  end

  def props
    @props ||= Properties.new.tap do |props|
      props.put(StreamsConfig::APPLICATION_ID_CONFIG, @id);
      props.put(StreamsConfig::BOOTSTRAP_SERVERS_CONFIG, ENV['KAFKA_BROKER'] || 'localhost:9092');
      props.put(StreamsConfig::DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
      props.put(StreamsConfig::DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
    end
  end
end
