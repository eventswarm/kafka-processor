require 'java'
require 'eventswarm-jar'
require 'rule'

java_import 'com.eventswarm.expressions.TrueExpression'
java_import 'com.eventswarm.expressions.SequenceExpression'

#
# Sample rule creator that matches any sequence of two events
#
# Use this as a template for other rule creators. Use of a 
# module here helps us to avoid malicious user input (we will
# only create instances of classes in this module)
#
module Rules
  class TwoTrue
    def create
      expr = SequenceExpression.new([TrueExpression.new,TrueExpression.new])
      Rule.new(expr, expr)
    end
  end
end
