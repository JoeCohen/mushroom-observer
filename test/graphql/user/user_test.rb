# frozen_string_literal: true

require("test_helper")
# ActionDispatch::IntegrationTest # ActiveSupport::TestCase
class Mutations::UserTest < IntegrationTestCase
  # def setup
  #   context = {
  #     session_user: context[:session_user]
  #   }
  # end

  # TODO: https://graphql-ruby.org/authorization/overview.html
  # Add authorization control to some fields in graphql/types/models/User.rb
  # that only the user should get, and put one of those in this query string
  # This query works OK - auth not currently required for any user field
  # query_string = "{ user( login: \"rolf\" ){ id name email password } }"

  # def test_find_user_by_id
  #   query_string = <<-GRAPHQL
  #     query($id: Int){
  #       user(id: $id) {
  #         name
  #         id
  #         email
  #         login
  #       }
  #     }
  #   GRAPHQL

  #   # user = rolf
  #   # user_id = MushroomObserverSchema.id_from_object(rolf, Types::Models::User, {})
  #   user_id = rolf.id

  #   result = MushroomObserverSchema.execute(query_string, variables: { id: user_id })
  #   user_result = result["data"]["user"]

  #   # Make sure the query worked
  #   assert_equal(user_id, user_result["id"])
  #   assert_equal("rolf", user_result["login"])
  # end

  # def good_signup_input
  #   {
  #     login: "Fred",
  #     email: "Fred@gmail.com",
  #     name: "Fred Waite",
  #     password: "123333",
  #     password_confirmation: "123333"
  #   }
  # end

  # def create_user(args = {}, context = {})
  #   Mutations::CreateUser.new(object: nil, field: nil, context: context).resolve(args)
  # end

  # def test_create_valid_user
  #   user = create_user(good_signup_input)

  #   assert(user.persisted?)
  #   assert_equal(user.name, "Fred Waite")
  #   assert_equal(user.email, "Fred@gmail.com")
  # end

  # def test_create_valid_user_integration
  #   query_string = <<-GRAPHQL
  #   mutation {
  #     createUser(
  #       input: {
  #         login: "Fred",
  #         email: "Fred@gmail.com",
  #         name: "Fred Waite",
  #         password: "123333",
  #         passwordConfirmation: "123333"
  #       }
  #     ) {
  #       id
  #       name
  #       email
  #     }
  #   }
  #   GRAPHQL

  #   user_result = MushroomObserverSchema.execute(query_string, context: {}, variables: {})
  #   # currently responds with a user not a node, or true. do we need to use connection?
  #   # puts(user_result.to_h)
  #   # {"data"=>{"createUser"=>{"id"=>1030180662, "name"=>"Fred Waite", "email"=>"Fred@gmail.com"}}}

  #   assert_equal("Fred Waite", user_result["data"]["createUser"]["name"])
  # end
end
