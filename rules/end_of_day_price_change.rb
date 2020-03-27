require 'java'
require 'rule'
require 'revs'
require 'revs/log4_j_logger'
require 'revs/triggers'

java_import 'com.eventswarm.events.JsonEvent'
java_import 'com.eventswarm.expressions.ValueGradientExpression'
java_import 'com.eventswarm.expressions.StringValueMatcher'
java_import 'com.eventswarm.eventset.EventMatchPassThruFilter'
java_import 'com.eventswarm.expressions.SequenceExpression'
java_import 'com.eventswarm.expressions.EventMatcherExpression'
java_import 'java.util.ArrayList'

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
  class EndOfDayPriceChange
    include Log4JLogger
    
    INCREASE=1

    def create(params = {})
      length = Integer(params["length"]) || 5
      path = params["path"] || 'open'
      symbol = params["symbol"] || 'MSFT'
      direction = Integer(params["direction"]) || INCREASE
      logger.warn("new EndOfDayPriceChange with length: #{length}, path: #{path}, symbol: #{symbol} and direction: #{direction}")
      filter = EventMatchPassThruFilter.new(StringValueMatcher.new(symbol, JsonEvent::StringRetriever.new('symbol')))
      gradient = ValueGradientExpression.new(length, JsonEvent::DoubleRetriever.new(path), direction)
      end_of_day = EventMatcherExpression.new(StringValueMatcher.new("End Of Day", JsonEvent::StringRetriever.new('event')))
      sequence = SequenceExpression.new(ArrayList.new([gradient, end_of_day]))
      Triggers.add(filter,sequence)
      Rule.new(filter, sequence, params)
    end
  end
end
