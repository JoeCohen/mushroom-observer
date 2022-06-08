# frozen_string_literal: true

class PatternSearch::BadSpeciesListError < PatternSearch::Error
  def to_s
    :pattern_search_bad_species_list_error.t(term: args[:var].inspect,
                                             value: args[:val].inspect)
  end
end
