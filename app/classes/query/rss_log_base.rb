module Query
  # Code common to all rss log queries.
  class RssLogBase < Query::Base
    include Query::Initializers::ContentFilters

    def model
      RssLog
    end

    def parameter_declarations
      super.merge(
        updated_at?: [:time],
        type?:       :string
      ).merge(content_filter_parameter_declarations(Observation)).
        merge(content_filter_parameter_declarations(Location))
    end

    def initialize_flavor
      initialize_model_do_time(:updated_at)
      add_rss_log_type_condition
      initialize_content_filters_for_rss_log(Observation)
      initialize_content_filters_for_rss_log(Location)
      super
    end

    def default_order
      "updated_at"
    end

    def types
      @types ||= (params[:type] || "all").to_s.split
    end

    def add_rss_log_type_condition
      return if types.include?("all")

      types = self.types
      types &= RssLog.all_types
      if types.empty?
        where << "FALSE"
      else
        where << types.map do |type|
          "rss_logs.#{type}_id IS NOT NULL"
        end.join(" OR ")
      end
    end
  end
end
