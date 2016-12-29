module Query
  # All users.
  class UserAll < Query::UserBase
    def initialize_flavor
      add_sort_order_to_title
      super
    end
  end
end
