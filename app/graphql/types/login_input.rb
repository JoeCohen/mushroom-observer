# frozen_string_literal: true

module Types
  class LoginInput < BaseInputObject
    description "Fields necessary for user login"
    # the name is usually inferred by class name but can be overwritten
    graphql_name "LoginInput"

    argument :login, String, required: true
    argument :password, String, required: true
  end
end
