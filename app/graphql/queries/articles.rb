# app/graphql/queries/articles.rb
module Queries
  class Articles < Queries::BaseQuery
    description "list all articles"
    type [Types::Models::Article], null: false

    def resolve
      ::Article.all
    end
  end
end
