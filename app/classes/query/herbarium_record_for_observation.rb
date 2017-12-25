module Query
  # HerbariumRecords attached to an Observation.
  class HerbariumRecordForObservation < Query::HerbariumRecordBase
    def parameter_declarations
      super.merge(
        observation: Observation
      )
    end

    def initialize_flavor
      obs = find_cached_parameter_instance(Observation, :observation)
      title_args[:observation] = obs.unique_format_name
      where << "herbarium_records_observations.observation_id = '#{obs.id}'"
      join  << :herbarium_records_observations
      super
    end
  end
end
