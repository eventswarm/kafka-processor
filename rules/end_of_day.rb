require 'java'
require 'rule'
require 'revs'
require 'revs/log4_j_logger'
require 'revs/triggers'

java_import 'com.eventswarm.events.JsonEvent'
java_import 'com.eventswarm.expressions.StringValueMatcher'
java_import 'com.eventswarm.expressions.EventMatcherExpression'

#
# Rule creator that looks for repeated price changes in a stream of stock quote events followed by end-of-day
#
# Four parameters are accepted:
#   symbol: stock symbol (default = 'MSFT')
#   length: number of consecutive events to match (default = 5)
#   path: path to json attribute (default = 'open')
#   direction: direction of change (up=1, flat=0, down=-1), (default=1)
#
module Rules
  class EndOfDay
    include Log4JLogger
    
    INCREASE=1

    def create(params = {})
      end_of_day = EventMatcherExpression.new(StringValueMatcher.new("End Of Day", JsonEvent::StringRetriever.new('event')))
      Rule.new(end_of_day, end_of_day, params)
    end
  end
end
