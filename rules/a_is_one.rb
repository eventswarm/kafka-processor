require 'java'
# require 'eventswarm-jar'
require 'rule'

java_import 'com.eventswarm.events.JsonEvent'
java_import 'com.eventswarm.expressions.ValueEqualsMatcher'
java_import 'com.eventswarm.expressions.EventMatcherExpression'
java_import 'com.eventswarm.expressions.ConstantValue'

#
# Sample rule creator that matches JSON with a top level attribute `a` having value 1
#
# Note that Java is an obtrusively verbose language, and static type safety forces us to use various wrappers around values
#
# Use this as a template for other rule creators. Use of a 
# module here helps us to avoid malicious user input (we will
# only create instances of classes in this module)
#
module Rules
  class AIsOne
    def create(params = {})
      expr = EventMatcherExpression.new(ValueEqualsMatcher.new(ConstantValue.new(1), JsonEvent::LongRetriever.new('a')))
      Rule.new(expr, expr, params)
    end
  end
end
