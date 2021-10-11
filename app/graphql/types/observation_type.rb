module Types
  class ObservationType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
    field :when, GraphQL::Types::ISO8601Date, null: true
    field :user_id, Integer, null: true
    field :specimen, Boolean, null: false
    field :notes, String, null: true
    field :thumb_image_id, Integer, null: true
    field :name_id, Integer, null: true
    field :location_id, Integer, null: true
    field :is_collection_location, Boolean, null: false
    field :vote_cache, Float, null: true
    field :num_views, Integer, null: false
    field :last_view, GraphQL::Types::ISO8601DateTime, null: true
    field :rss_log_id, Integer, null: true
    field :lat, Float, null: true
    field :long, Float, null: true
    field :where, String, null: true
    field :alt, Integer, null: true
    field :lifeform, String, null: true
    field :text_name, String, null: true
    field :classification, String, null: true
    field :gps_hidden, Boolean, null: false
  end
end
