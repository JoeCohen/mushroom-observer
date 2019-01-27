class API
  module Parsers
    # Parse strings for API.
    class StringParser < Base
      def parse(str)
        limit = args[:limit]
        raise StringTooLong.new(str, limit) if limit && str.size > limit

        str
      end
    end
  end
end
