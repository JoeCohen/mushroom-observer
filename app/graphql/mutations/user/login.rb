# frozen_string_literal: true

module Mutations::User
  class Login < Mutations::BaseMutation
    description "Login a user"

    # RelayClassicMutation only accepts single input
    argument :input, Inputs::User::Login, required: true

    field :token, String, null: true
    field :user, Types::Models::UserType, null: true

    def resolve(input: nil)
      puts("input.inspect")
      puts(input.inspect)
      user = User.authenticate(**input)
      puts("user.inspect")
      puts(user.inspect)

      return {} unless user

      raise(GraphQL::ExecutionError.new("User not verified")) unless
        user.verified

      # admin = user.admin

      now = Time.zone.now
      args = {
        last_login: now,
        updated_at: now
      }
      user.update(args)

      token = ::Token.new(user_id: user.id,
                          in_admin_mode: false).encrypt_to_header

      # This is what the resolver returns:
      {
        user: user, # For debugging
        token: token
      }
    rescue ActiveRecord::RecordNotFound
      raise(GraphQL::ExecutionError.new("user not found"))
    end

    # https://www.howtographql.com/graphql-ruby/4-authentication/
  end
end
