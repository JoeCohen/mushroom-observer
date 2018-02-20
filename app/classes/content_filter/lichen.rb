class ContentFilter
  # Content filter specifically to filter out or just show lichens.
  class Lichen < BooleanFilter
    def initialize
      super(
        sym:         :lichen,
        models:      [Observation, Name],
        on_vals:     ["no", "yes"],
        prefs_vals:  ["no", "yes"],
        off_val:     nil
      )
    end

    def sql_conditions(_query, model, val)
      # Note the critical difference -- the extra spaces in the negative
      # version.  This allows all lifeforms containing the word "lichen" to be
      # selected for in the positive version, but only excudes the one lifeform
      # in the negative.
      table = model == Name ? "names" : "observations"
      if val
        "#{table}.lifeform LIKE '%lichen%'"
      else
        "#{table}.lifeform NOT LIKE '% lichen %'"
      end
    end
  end
end
