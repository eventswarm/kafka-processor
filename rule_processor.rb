require 'java'
require 'jbundler'
require 'revs'
require 'revs/triggers'
require 'revs/log4_j_logger'
require 'json'

java_import 'org.apache.kafka.streams.processor.AbstractProcessor'
java_import 'org.apache.kafka.streams.processor.ProcessorSupplier'
java_import 'com.eventswarm.AddEventTrigger'
java_import 'com.eventswarm.AddEventAction'
java_import 'com.eventswarm.events.Activity'
java_import 'com.eventswarm.events.jdo.OrgJsonEvent'
java_import 'com.eventswarm.events.jdo.JdoHeader'
java_import 'com.eventswarm.events.jdo.JdoSource'
java_import 'org.json.JSONObject'
java_import 'org.json.JSONTokener'
java_import 'com.eventswarm.eventset.LastNWindow'

NAMESPACE='kafka'.freeze

class RuleProcessor < AbstractProcessor
  include AddEventTrigger
  include AddEventAction
  include Log4JLogger

  def initialize(rule)
    super()
    @rule = rule
    logger.warn("Establishing processor for rule with params #{@rule.params}")
    Triggers.add(@rule.match_set, self) # catch matches from the rule
  end

  #
  # Construct an EventSwarm event and pass it onwards to the rule for matching
  #
  # Assumes that we always receive JSON and will log exceptions
  #
  def process(key, value)
    json = JSONObject.new(JSONTokener.new(value))
    header = JdoHeader.new(java.util.Date.new(context.timestamp), source, id)
    event = OrgJsonEvent.new(header, json)
    @rule.add_action.execute(self, event)
  rescue => exc
    logger.error(exc.to_s + exc.backtrace.join("\n"))
  end

  #
  # When we have a match, forward it to the configured SINK or other downstream component
  #
  def execute(_trigger, event)
    context.forward(forwards_key, match_notification(event))
  end

  #
  # Since we're using java objects here, I can't rely on the json gem and need to encode explicitly 
  #
  def match_notification(event)
    logger.warn("Match for rule with params #{@rule.params} and action #{@rule.add_action}")
    "{\"rule\": #{@rule.params.to_json}, \"match\": #{as_json(event)}}"
  end

  def as_json(event)
    if event.is_a?(Activity)
      # publish an array of the events in the match
      "[#{event.get_events.map{|event| event.get_json_string}.join(',')}]"
    else
      # publish just the event that matched
      event.get_json_string
    end
 end

  #
  # generate a unique id based on the record context
  #
  def id
    "#{NAMESPACE}#{context.topic}:#{context.partition}:#{context.offset}"
  end

  #
  # generate a source identifier based on the record context
  #
  def source
    JdoSource.new("#{NAMESPACE}:#{forwards_key}")
  end

  #
  # generate a key that ensures matches are partioned in a manner consistent with the
  # triggering event by concatenating the topic and partition id
  #
  def forwards_key
    "#{context.topic}:#{context.partition}"
  end

  #
  # defined for consistency with the AddEventTrigger contract, but we know we only send 
  # newly constructed events to the rule's add_action
  #
  def register_action(action); end
end
