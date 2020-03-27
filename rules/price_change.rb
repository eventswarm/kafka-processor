require 'java'
require 'rule'
require 'revs'
require 'revs/triggers'
require 'revs/log4_j_logger'

java_import 'com.eventswarm.events.JsonEvent'
java_import 'com.eventswarm.expressions.ValueGradientExpression'
java_import 'com.eventswarm.expressions.StringValueMatcher'
java_import 'com.eventswarm.eventset.EventMatchPassThruFilter'

#
# Rule creator that looks for repeated price changes in a stream of stock quote events
#
# Four parameters are accepted:
#   symbol: stock symbol (default = 'MSFT')
#   length: number of consecutive events to match (default = 5)
#   path: path to json attribute (default = 'open')
#   direction: direction of change (up=1, flat=0, down=-1), (default=1)
#
module Rules
  class PriceChange
    include Log4JLogger

    INCREASE=1

    def create(params = {})
      length = Integer(params["length"]) || 5
      path = params["path"] || 'open'
      symbol = params["symbol"] || 'MSFT'
      direction = Integer(params["direction"]) || INCREASE
      logger.warn("new PriceChange with length: #{length}, path: #{path}, symbol: #{symbol} and direction: #{direction}")
      filter = EventMatchPassThruFilter.new(StringValueMatcher.new(symbol, JsonEvent::StringRetriever.new('symbol')))
      expr = ValueGradientExpression.new(length, JsonEvent::DoubleRetriever.new(path), direction)
      Triggers.add(filter, expr)
      Rule.new(filter, expr, params)
    end
  end
end
