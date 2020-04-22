class SearchController < ApplicationController

  before_action :login_required, except: [
    :advanced_search_form,
    :pattern_search,
  ]

  before_action :disable_link_prefetching

  # This is the action the search bar commits to.  It just redirects to one of
  # several "foreign" search actions:
  #   comment/comment_search
  #   image/image_search
  #   location/location_search
  #   name/name_search
  #   observation/observation_search
  #   user/user_search
  #   project/project_search
  #   species_list/species_list_search
  def pattern_search # :norobots:
    pattern = param_lookup([:search, :pattern]) { |p| p.to_s.strip_squeeze }
    type = param_lookup([:search, :type], &:to_sym)

    # Save it so that we can keep it in the search bar in subsequent pages.
    session[:pattern] = pattern
    session[:search_type] = type

    case type
    when :comment, :herbarium, :herbarium_record, :image, :location, :name,
      :observation, :project, :species_list, :user
      ctrlr = type
    when :google
      site_google_search(pattern)
      return
    else
      flash_error(:runtime_invalid.t(type: :search, value: type.inspect))
      redirect_back_or_default(action: :list_rss_logs)
      return
    end

    # If pattern is blank, this would devolve into a very expensive index.
    if pattern.blank?
      redirect_to(controller: ctrlr, action: "list_#{type}s")
    else
      redirect_to(controller: ctrlr, action: "#{type}_search",
                  pattern: pattern)
    end
  end

  def site_google_search(pattern)
    if pattern.blank?
      redirect_to(action: :list_rss_logs)
    else
      search = URI.encode_www_form(q: "site:#{MO.domain} #{pattern}")
      redirect_to("https://google.com/search?#{search}")
    end
  end

  # Advanced search form.  When it posts it just redirects to one of several
  # "foreign" search actions:
  #   image/advanced_search
  #   location/advanced_search
  #   name/advanced_search
  #   observation/advanced_search
  def advanced_search_form # :norobots:
    @filter_defaults = users_content_filters || {}
    return unless request.method == "POST"

    model = params[:search][:model].to_s.camelize.constantize
    query_params = {}
    add_filled_in_text_fields(query_params)
    add_applicable_filter_parameters(query_params, model)
    query = create_query(model, :advanced_search, query_params)
    redirect_to(add_query_param({ controller: model.show_controller,
                                  action: :advanced_search },
                                query))
  end

  def add_filled_in_text_fields(query_params)
    [:content, :location, :name, :user].each do |field|
      val = params[:search][field].to_s
      next unless val.present?

      # Treat User field differently; remove angle-bracketed user name,
      # since it was included by the auto-completer only as a hint.
      if field == :user
        val = val.sub(/ <.*/, "")
      end
      query_params[field] = val
    end
  end

  def add_applicable_filter_parameters(query_params, model)
    ContentFilter.by_model(model).each do |fltr|
      query_params[fltr.sym] = params[:"content_filter_#{fltr.sym}"]
    end
  end

end
