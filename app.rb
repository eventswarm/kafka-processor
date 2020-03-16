# app.rb

# include current directory in load path since our dynamically loaded rules rely on it
$:.unshift(File.dirname(__FILE__)).uniq!

require 'sinatra'
require 'sinatra/json'
require 'java'
require 'jbundler'
require 'eventswarm-jar'
require 'log4j-jar'
require 'revs/log4_j_logger'
require 'rule'
require 'rule_processor'
require 'stream'

java_import 'org.apache.kafka.streams.processor.AbstractProcessor'
java_import 'org.apache.kafka.streams.processor.ProcessorSupplier'
java_import 'com.eventswarm.expressions.TrueExpression'

# make sure we can connect from anywhere
set :bind, '0.0.0.0'
set :streams, {}
set :rulesdir, File.join(File.dirname(__FILE__), "rules")

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

def make_stream(params, supplier, name)
  stream = Stream.new(params[:input], params[:output], supplier, name)
  stream.start
  settings.streams[stream.id] = stream # save the stream
  stream.to_h
end

def json_params(request)
  body = request.body.read
  body.empty? ? {} : JSON.parse(body)
end

def classify_rule(str)
  Object.const_get("Rules::" + str.split('_').map(&:capitalize).join)
end

get '/ping' do
  "pong\n"
end

# copy records from input topic to output topic using simple copier
post '/copy' do
  content_type :json
  params.merge!(json_params(request)) # accept params either via JSON or URL

  supplier = BlockSupplier.new do 
    Copier.new
  end
  json(make_stream(params, supplier, "copy")) + "\n"
end

post '/true' do
  content_type :json
  params.merge!(json_params(request)) # accept params either via JSON or URL

  
  supplier = BlockSupplier.new do
    expr = TrueExpression.new   # use an always true expression
    rule = Rule.new(expr, expr) # expression is both entry point and match trigger
    RuleProcessor.new(rule)
  end
  json(make_stream(params, supplier, "true")) + "\n"
end

post '/stream/:rule' do
  content_type :json
  params.merge!(json_params(request)) # accept params either via JSON or URL

  load File.join(settings.rulesdir, "#{params[:rule]}.rb")
  klass = classify_rule(params[:rule])
  supplier = BlockSupplier.new{ RuleProcessor.new(klass.new.create) }
  json(make_stream(params, supplier, params[:rule])) + "\n"
end

get '/stream/:id' do |id|
  json(settings.streams[id].to_h) + "\n"
end

get '/streams' do 
  json(settings.streams.values.map{|value| value.to_h }) + "\n"
end
  
delete '/stream/:id' do |id|
  settings.streams[id].close
  settings.streams.delete(id)
end
