module Query
  # All projects.
  class ProjectAll < Query::ProjectBase
    def initialize_flavor
      add_sort_order_to_title
      super
    end
  end
end
