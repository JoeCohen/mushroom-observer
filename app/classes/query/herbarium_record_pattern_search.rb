# frozen_string_literal: true

class Query::HerbariumRecordPatternSearch < Query::HerbariumRecordBase
  def parameter_declarations
    super.merge(
      pattern: :string
    )
  end

  def initialize_flavor
    add_search_condition(search_fields, params[:pattern])
    super
  end

  def search_fields
    "CONCAT(" \
      "herbarium_records.initial_det," \
      "herbarium_records.accession_number," \
      "COALESCE(herbarium_records.notes,'')" \
      ")"
  end
end
