# frozen_string_literal: true

require("test_helper")
require("set")

module Locations
  class MergesControllerTest < FunctionalTestCase
    include ObjectLinkHelper

    def test_list_merge_options
      albion = locations(:albion)

      # Full match with albion.
      requires_login(:new, where: albion.display_name)
      assert_obj_arrays_equal([albion], assigns(:matches))

      # Should match against albion.
      requires_login(:new, where: "Albion, CA")
      assert_obj_arrays_equal([albion], assigns(:matches))

      # Should match against albion.
      requires_login(:new, where: "Albion Field Station, CA")
      assert_obj_arrays_equal([albion], assigns(:matches))

      # Shouldn't match anything.
      requires_login(:new, where: "Somewhere out there")
      assert_nil(assigns(:matches))
    end
  end
end