# frozen_string_literal: true

# The original MO controller and hence a real mess!
# The Clitocybe of controllers.
#
class ObserverController < ApplicationController
  # These need to be moved into the files where they are actually used.
  require "find"
  require "set"

  # These will mostly form the new ObservationController:
  include Other, Suggestions, SiteStats, Indexes, CreateAndEditObservation,
          ShowObservation

  # These all belong in new controllers:
  include UserController, SearchController, RssLogController, MarkupController,
          InfoController, EmailController, AuthorController

  # Disable cop: all these methods are defined in files included above.
  # rubocop:disable Rails/LexicallyScopedActionFilter

  before_action :login_required, except: [
    :ask_webmaster_question,
    :how_to_help,
    :how_to_use,
    :index_rss_log,
    :intro,
    :list_rss_logs,
    :lookup_observation,
    :next_observation,
    :next_rss_log,
    :prev_observation,
    :prev_rss_log,
    :rss,
    :show_obs,
    :show_observation,
    :show_rss_log,
    :test,
    :turn_javascript_nil,
    :turn_javascript_off,
    :turn_javascript_on
  ]
  # except: [
  #   :advanced_search,
  #   :advanced_search_form,
  #   :ask_webmaster_question,
  #   :checklist,
  #   :download_observations,
  #   :hide_thumbnail_map,
  #   :how_to_help,
  #   :how_to_use,
  #   :index,
  #   :index_observation,
  #   :index_rss_log,
  #   :index_user,
  #   :intro,
  #   :list_observations,
  #   :list_rss_logs,
  #   :lookup_accepted_name,
  #   :lookup_comment,
  #   :lookup_image,
  #   :lookup_location,
  #   :lookup_name,
  #   :lookup_observation,
  #   :lookup_project,
  #   :lookup_species_list,
  #   :lookup_user,
  #   :map_observation,
  #   :map_observations,
  #   :news,
  #   :next_observation,
  #   :next_rss_log,
  #   :next_user,
  #   :observation_search,
  #   :observations_by_name,
  #   :observations_of_look_alikes,
  #   :observations_of_name,
  #   :observations_of_related_taxa,
  #   :observations_by_user,
  #   :observations_for_project,
  #   :observations_at_where,
  #   :observations_at_location,
  #   :pattern_search,
  #   :prev_observation,
  #   :prev_rss_log,
  #   :prev_user,
  #   :print_labels,
  #   :rss,
  #   :search_bar_help,
  #   :show_obs,
  #   :show_observation,
  #   :show_rss_log,
  #   :show_site_stats,
  #   :show_user,
  #   :test,
  #   :textile,
  #   :textile_sandbox,
  #   :throw_error,
  #   :throw_mobile_error,
  #   :translators_note,
  #   :turn_javascript_nil,
  #   :turn_javascript_off,
  #   :turn_javascript_on,
  #   :user_search,
  #   :users_by_contribution,
  #   :w3c_tests,
  #   :wrapup_2011
  # ]

  before_action :disable_link_prefetching, except: [
    :create_observation,
    :edit_observation,
    :show_obs,
    :show_observation,
    :show_user
  ]

  # rubocop:enable Rails/LexicallyScopedActionFilter

  around_action :skip_bullet, if: -> { defined?(Bullet) }, only: [
    # Bullet wants us to eager load species_list.observations when removing
    # an observation from a species_list, but I can't figure out how.
    :edit_observation
  ]
end
