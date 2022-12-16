# frozen_string_literal: true

require("test_helper")

# test the NameTracker model
class NameTrackerTest < UnitTestCase
  def test_summary
    name_tracker = name_trackers(:coprinus_comatus_name_tracker)
    obj = Name.find(name_tracker.obj_id)
    assert_match(obj.display_name, name_tracker.summary)
    interest = Interest.find_by(target: name_tracker)
    assert_match(interest.target_id, name_tracker.id)
  end

  def test_no_user
    name_tracker = name_trackers(:coprinus_comatus_name_tracker)
    name_tracker.user = nil

    assert_not(name_tracker.save)
    assert(name_tracker.errors[:user].any?)
  end
end
