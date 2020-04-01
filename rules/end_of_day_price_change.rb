require 'java'
require 'rule'
require 'revs'
require 'revs/log4_j_logger'
require 'revs/triggers'

java_import 'com.eventswarm.events.JsonEvent'
java_import 'com.eventswarm.expressions. GradientExpression'
java_import 'com.eventswarm.expressions.StringValueMatcher'
java_import 'com.eventswarm.expressions.ANDMatcher'
java_import 'com.eventswarm.expressions.ORMatcher'
java_import 'com.eventswarm.eventset.EventMatchPassThruFilter'
java_import 'com.eventswarm.expressions.StrictSequenceExpression'
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

    attr_reader :length, :path, :symbol, :direction, :min
    
    INCREASE=1

    def create(params = {})
      process_params(params)
      logger.warn("new EndOfDayPriceChange with length: #{@length}, min: #{@min}, path: #{@path}, symbol: #{@symbol} and direction: #{@direction}")
      prefilter = filter(@symbol)
      gradient = ValueGradientExpression.new(@length, JsonEvent::DoubleRetriever.new(@path), @direction, @min)
      end_of_day = EventMatcherExpression.new(match_eod)
      sequence = StrictSequenceExpression.new(ArrayList.new([gradient, end_of_day]))
      Triggers.add(prefilter,sequence)
      Rule.new(prefilter, sequence, params)
    end

    def process_params(params) 
      @length = string_to_int(params["length"], 5)
      @path = params["path"] || 'open'
      @symbol = params["symbol"] || 'MSFT'
      @direction = Integer(params["direction"]) || INCREASE
      @min = string_to_int(params["min"], @length)
    end

    #
    # Create a filter that ensures only quote and end_of_day events for the specified symbol are processed
    #
    def filter(symbol)
      match_symbol = matcher(symbol, 'symbol') 
      match_quote = matcher('quote', 'event')
      quote_or_eod = ORMatcher.new(ArrayList.new([match_eod, match_quote]))
      EventMatchPassThruFilter.new(ANDMatcher.new(ArrayList.new([match_symbol, quote_or_eod])))
    end

    #
    # Want to use this matcher more than once
    #
    def match_eod
      @_match_eod ||= matcher('End Of Day', 'event')
    end
    
    #
    # Create an EventSwarm matcher that matches the specified value at the specified path in a JSON event
    #
    def matcher(value, path)
      StringValueMatcher.new(value, JsonEvent::StringRetriever.new(path))
    end

    #
    # Convert a string parameter to an integer safely, accounting for nil values and assigning a default if nil
    #
    def string_to_int(param, default = 0)
      param.nil? ? default : Integer(param)
    end
  end
end
