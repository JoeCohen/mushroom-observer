# frozen_string_literal: true

class API2
  module Parsers
    # Parse species lists for API2.
    class SpeciesListParser < ObjectBase
      def model
        SpeciesList
      end

      def try_finding_by_string(str)
        SpeciesList.find_by_title(str)
      end
    end
  end
end
