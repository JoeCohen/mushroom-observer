module Types::Models
  class Naming < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
    field :observation_id, Integer, null: true
    field :observation, Types::Models::Observation, null: true
    field :name_id, Integer, null: true
    field :name, Types::Models::Name, null: true
    field :user_id, Integer, null: true
    field :user, Types::Models::User, null: true
    field :vote_cache, Float, null: true
    field :reasons, String, null: true

    field :votes, [Types::Models::Vote], null: true
  end
end
