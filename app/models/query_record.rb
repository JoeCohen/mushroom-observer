# frozen_string_literal: true

#  = Query Record Model
#
#  Query Records store the parameters of recent user queries for quicker access.
#  Queries can be nested (inner/outer); if query_record is for an inner query,
#  the `outer_id` is also stored.
#  Used by MO's Query::Modules::ActiveRecord
#
#  == Attributes
#
#  id::             Locally unique numerical id.
#  updated_at::     Date/time it was last updated.
#  access_count::   Number of times the query record was accessed.
#  description::    Serialized parameters of the query.
#  outer_id::       `id` of outer query, when inner query of a nested query.
#
#  == Class methods
#
#  QueryRecord.cleanup::     Removes all qr's older than one day.

# access query records saved in the db
class QueryRecord < ApplicationRecord
  require "arel-helpers"
  include ArelHelpers::ArelTable

  attr_accessor :query

  def query # rubocop:disable Lint/DuplicateMethods
    ::Query.deserialize(description)
  end

  # Nimmo Note: Original SQL.
  # DELETE FROM #{table_name}  <-- this was always `query_records`, var unneeded
  # WHERE
  #   access_count = 0 AND updated_at < DATE_SUB(NOW(), INTERVAL 6 HOUR) OR
  #   access_count > 0 AND updated_at < DATE_SUB(NOW(), INTERVAL 1 DAY)
  # Jason proposed removing the access_count check 5/2022 and using < 1 DAY

  # Only keep states around for a day.
  # This goes through the whole lot and destroys old ones.
  def self.cleanup
    return unless !defined?(@@last_cleanup) ||
                  (@@last_cleanup < 5.minutes.ago) ||
                  ::Rails.env.test?

    QueryRecord.where(QueryRecord[:updated_at] < 1.day.ago).delete_all

    @@last_cleanup = Time.zone.now
  end
end
