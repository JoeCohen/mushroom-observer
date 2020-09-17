# frozen_string_literal: true

class API2
  module Parsers
    # Parse altitudes for API.
    class AltitudeParser < CoordinateParser
      def parse(str)
        super(:altitude, str)
      end
    end
  end
end
