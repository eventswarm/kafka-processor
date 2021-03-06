require 'java'
require 'jbundler'
require 'revs'
require 'revs/log4_j_logger'
require 'revs/triggers'

java_import 'com.eventswarm.expressions.ExpressionMatchSet'
java_import 'com.eventswarm.eventset.LastNWindow'
java_import 'com.eventswarm.expressions.ComplexExpression'

MAX_MATCHES = 100

class Rule
  include Log4JLogger
  
  attr_reader :match_set, :add_action, :params

  #
  # New rule for use by the rule processor
  #   add_action = entry point to the expression
  #   match_trigger = expression component from which matches should be collected
  #   params = parameters to include in matches for correlation (e.g. rule name, stock symbol)
  #
  def initialize(add_action, match_trigger, params)
    @params = params
    @add_action = add_action
    @match_set = ExpressionMatchSet.new(LastNWindow.new(MAX_MATCHES))
    match_trigger.is_a?(ComplexExpression) ? 
      Triggers.complex_match(match_trigger, @match_set) : 
      Triggers.match(match_trigger, @match_set)
  end
end
