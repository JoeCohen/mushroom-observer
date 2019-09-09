class Query::ObservationAll < Query::ObservationBase
  def initialize_flavor
    add_sort_order_to_title
    refine_title
    super
  end

  def coerce_into_image_query
    do_coerce(:Image)
  end

  def coerce_into_location_query
    do_coerce(:Location)
  end

  def coerce_into_name_query
    do_coerce(:Name)
  end

  def do_coerce(new_model)
    Query.lookup(new_model, :with_observations, params_plus_old_by)
  end

  private

  def refine_title
    return unless params.include?(:names)

    # Observations matching "<names>"
    self.title_tag = :query_title_pattern_search
    text_names = Name.where(id: params[:names]).pluck(:text_name)
    self.title_args[:pattern] = text_names.join(", ")
  end
end
