class Query::ObservationAdvancedSearch < Query::ObservationBase
  include Query::Initializers::AdvancedSearch

  def parameter_declarations 
    super.merge(
      advanced_search_parameter_declarations
    )
  end

  def initialize_flavor
    initialize_advanced_search
    super
  end

  def add_join_to_names
    add_join(:names)
  end

  def add_join_to_users
    add_join(:users)
  end

  def add_join_to_locations
    add_join(:locations!)
  end

  def content_join_spec
    :comments
  end

  def coerce_into_image_query
    Query.lookup(:Image, :with_observations_in_set, ids: result_ids)
  end

  def coerce_into_location_query
    Query.lookup(:Location, :with_observations_in_set, ids: result_ids)
  end

  def coerce_into_name_query
    Query.lookup(:Name, :with_observations_in_set, ids: result_ids)
  end
end
