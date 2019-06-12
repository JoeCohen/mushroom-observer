module Query
  # Names with observations.
  class NameWithObservations < Query::NameBase
    include Query::Initializers::ContentFilters

    def parameter_declarations
      super.merge(
        old_by?:           :string,
        date?:             [:date],
        projects?:         [:string],
        herbaria?:         [:string],
        herbarium_records?: [:string],
        confidence?:       [:float],
        is_collection_location?: :boolean,
        has_location?:     :boolean,
        has_name?:         :boolean,
        has_sequences?:    { boolean: [true] },
        has_notes_fields?: [:string],
        north?:            :float,
        south?:            :float,
        east?:             :float,
        west?:             :float
      ).merge(content_filter_parameter_declarations(Observation))
    end

    def initialize_flavor
      add_join(:observations)
      initialize_created_at_condition
      initialize_updated_at_condition
      initialize_date_condition
      initialize_users_condition
      initialize_projects_condition
      initialize_herbaria_condition
      initialize_herbarium_records_condition
      initialize_confidence_condition
      initialize_notes_has_condition
      initialize_is_collection_location_condition
      initialize_has_location_condition
      initialize_has_name_condition
      initialize_has_notes_condition
      initialize_has_comments_condition
      initialize_comments_has_condition
      initialize_has_sequences_condition
      initialize_has_notes_fields_condition
      initialize_model_do_observation_bounding_box
      initialize_content_filters(Observation)
      super
    end

    def initialize_created_at_condition
      initialize_model_do_time(:created_at, "observations.created_at")
    end

    def initialize_updated_at_condition
      initialize_model_do_time(:updated_at. "observations.updated_at")
    end

    def initialize_date_condition
      initialize_model_do_date(:date, "observations.when")
    end

    def initialize_users_condition
      initialize_model_do_objects_by_id(:users, "observations.user_id")
    end

    def initialize_projects_condition
      initialize_model_do_objects_by_name(
        Project, :projects,
        "observations_projects.project_id",
        join: { observations: :observations_projects }
      )
    end

    def initialize_herbaria_condition
      initialize_model_do_objects_by_name(
        Herbarium, :herbaria,
        "herbarium_records.herbarium_id",
        join: {
          observations: {
            herbarium_records_observations: :herbarium_records
          }
        }
      )
    end

    def initialize_herbarium_records_condition
      initialize_model_do_objects_by_name(
        HerbariumRecord, :herbarium_records,
        "herbarium_records_observations.herbarium_record_id",
        join: { observations: :herbarium_records_observations }
      )
    end

    def initialize_confidence_condition
      initialize_model_do_range(:confidence, "observations.vote_cache")
    end

    def initialize_notes_has_condition
      initialize_model_do_search(:notes_has, "observations.notes")
    end

    def initialize_is_collection_location_condition
      initialize_model_do_boolean(
        :is_collection_location,
        "observations.is_collection_location IS TRUE",
        "observations.is_collection_location IS FALSE"
      )
    end

    def initialize_has_location_condition
      initialize_model_do_boolean(
        :has_location,
        "observations.location_id IS NOT NULL",
        "observations.location_id IS NULL"
      )
    end

    def initialize_has_name_condition
      return if params[:has_name].nil?

      genus = Name.ranks[:Genus]
      group = Name.ranks[:Group]
      initialize_model_do_boolean(
        :has_name,
        "names.rank <= #{genus} or names.rank = #{group}",
        "names.rank > #{genus} and names.rank < #{group}"
      )
    end

    def initialize_has_notes_condition
      initialize_model_do_boolean(
        :has_notes,
        "observations.notes != #{escape(Observation.no_notes_persisted)}",
        "observations.notes  = #{escape(Observation.no_notes_persisted)}"
      )
    end

    def initialize_has_comments_condition
      return unless params[:has_comments]

      add_join({ observations: :comments })
    end

    def initialize_comments_has_condition
      return unless params[:comments_has].present?

      initialize_model_do_search(
        :comments_has,
        "CONCAT(comments.summary,COALESCE(comments.comment,''))"
      )
      add_join({ observations: :comments })
    end

    def initialize_has_sequences_condition
      return unless params[:has_sequences]

      add_join({ observations: :sequences })
    end

    def initialize_has_notes_fields_condition
      initialize_model_do_has_notes_fields(:has_notes_fields)
    end

    def coerce_into_observation_query
      Query.lookup(:Observation, :all, params_with_old_by_restored)
    end
  end
end
