# frozen_string_literal: true

class API2
  module Parsers
    # Parse herbarium_records for API2.
    class HerbariumRecordParser < ObjectBase
      def model
        HerbariumRecord
      end
    end
  end
end
