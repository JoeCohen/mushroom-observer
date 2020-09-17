# frozen_string_literal: true

class API2
  module Parsers
    # Parse booleans for API2.
    class BooleanParser < Base
      def parse(str)
        val = positive?(str)
        limit = args[:limit]
        return val if !limit || val == limit

        raise(BadLimitedParameterValue.new(str, [limit]))
      end

      private

      def positive?(str)
        case str.downcase
        when "1", "yes", "true", :yes.l then true
        when "0", "no", "false", :no.l then false
        else
          raise(BadParameterValue.new(str, :boolean))
        end
      end
    end
  end
end
