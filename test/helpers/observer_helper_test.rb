# frozen_string_literal: true
require "test_helper"

# test the helpers for ObserverController
class ObserverHelperTest < ActionView::TestCase
  def test_show_observation_name
    user = users(:rolf)
    location = locations(:albion)

    # approved name
    current_name = names(:lactarius_alpinus)
    obs = Observation.create!(
      name: current_name, user: user, when: Time.now, where: location
    )
    assert_equal(current_name.short_display_name.t,
                 obs_title_consensus_id(current_name))

    # deprecated name
    deprecated_name = names(:lactarius_alpigenes)
    obs = Observation.create!(
      name: deprecated_name, user: user, when: Time.now, where: location
    )
    assert_equal("#{deprecated_name.short_display_name.t} " \
                 "(#{current_name.short_display_name.t})",
                 obs_title_consensus_id(deprecated_name))
  end
end
