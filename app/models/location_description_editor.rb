# frozen_string_literal: true

# Glue table between location_descriptions and users.
class LocationDescriptionEditor < ApplicationRecord
  belongs_to :location_description
  belongs_to :user
end
