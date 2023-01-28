# frozen_string_literal: true

require("test_helper")

# ----------------------------
#  Lookup's.
#  These are links like /lookup_name/Amanita+muscaria
#  They can be created by the Textile Sandbox, and should always redirect
#  to the appropriate model.
# /lookup_accepted_name is intended for use by other web sites
# ----------------------------
class LookupsControllerTest < FunctionalTestCase
  def test_lookup_comment
    login
    c_id = comments(:minimal_unknown_obs_comment_1).id
    get(:lookup_comment, params: { id: c_id })
    assert_redirected_to(comment_path(id: c_id))
    get(:lookup_comment, params: { id: 10_000 })
    assert_redirected_to(comments_path)
    assert_flash_error
  end

  def test_lookup_image
    login
    i_id = images(:in_situ_image).id
    get(:lookup_image, params: { id: i_id })
    assert_redirected_to(image_path(i_id))
    get(:lookup_image, params: { id: 10_000 })
    assert_redirected_to(images_path)
    assert_flash_error
  end

  def test_lookup_location
    login
    l_id = locations(:albion).id
    get(:lookup_location, params: { id: l_id })
    assert_redirected_to(location_path(id: l_id))
    get(:lookup_location, params: { id: "Burbank, California" })
    assert_redirected_to(location_path(locations(:burbank).id))
    get(:lookup_location, params: { id: "California, Burbank" })
    assert_redirected_to(location_path(locations(:burbank).id))
    get(:lookup_location, params: { id: "Zyzyx, Califonria" })
    assert_redirected_to(locations_path)
    assert_flash_error
    get(:lookup_location, params: { id: "California" })
    # assert_redirected_to(locations_path)
    # Must test against regex because passed query param borks path match
    assert_redirected_to(%r{/locations})
    assert_flash_warning
  end

  def test_lookup_accepted_name
    login
    get(:lookup_accepted_name,
        params: { id: names(:lactarius_subalpinus).text_name })
    assert_redirected_to(name_path(names(:lactarius_alpinus)))
  end

  def test_lookup_name
    login
    n_id = names(:fungi).id
    get(:lookup_name, params: { id: n_id })
    assert_redirected_to(name_path(n_id))

    get(:lookup_name, params: { id: names(:coprinus_comatus).id })
    # Must test against regex because passed query param borks path match
    assert_redirected_to(%r{/names/#{names(:coprinus_comatus).id}})

    get(:lookup_name, params: { id: "Agaricus campestris" })
    assert_redirected_to(name_path(names(:agaricus_campestris).id))

    get(:lookup_name, params: { id: "Agaricus newname" })
    assert_redirected_to(names_path)
    assert_flash_error

    get(:lookup_name, params: { id: "Amanita baccata sensu Borealis" })
    assert_redirected_to(name_path(names(:amanita_baccata_borealis).id))

    get(:lookup_name, params: { id: "Amanita baccata" })
    # Must test against regex because passed query param borks path match
    assert_redirected_to(%r{/names})
    assert_flash_warning

    get(:lookup_name, params: { id: "Agaricus campestris L." })
    assert_redirected_to(name_path(names(:agaricus_campestris).id))

    get(:lookup_name, params: { id: "Agaricus campestris Linn." })
    assert_redirected_to(name_path(names(:agaricus_campestris).id))

    # Prove that when there are no hits and exactly one spelling suggestion,
    # it gives a flash warning and shows the page for the suggestion.
    get(:lookup_name, params: { id: "Fungia" })
    assert_flash_text(:runtime_suggest_one_alternate.t(type: :name,
                                                       match: "Fungia"))
    assert_redirected_to(name_path(names(:fungi).id))

    # Prove that when there are no hits and >1 spelling suggestion,
    # it flashes a warning and shows the name index
    get(:lookup_name, params: { id: "Verpab" })
    assert_flash_text(:runtime_suggest_multiple_alternates.t(type: :name,
                                                             match: "Verpab"))
    # Must test against regex because passed query param borks path match
    assert_redirected_to(%r{/names})

    # Prove that lookup_name adds flash message when it hits an error,
    # stubbing a method called by lookup_name in order to provoke an error.
    LookupsController.any_instance.stubs(:fix_name_matches).
      raises(RuntimeError)
    get(:lookup_name, params: { id: names(:fungi).text_name })
    assert_flash_text("RuntimeError")
  end

  def test_lookup_observation
    login
    get(:lookup_observation,
        params: { id: observations(:minimal_unknown_obs).id })
    assert_redirected_to(
      permanent_observation_path(observations(:minimal_unknown_obs).id)
    )
  end

  def test_lookup_project
    login
    p_id = projects(:eol_project).id
    get(:lookup_project, params: { id: p_id })
    assert_redirected_to(/#{project_path(p_id)}/)
    get(:lookup_project, params: { id: "Bolete" })
    assert_redirected_to(/#{project_path(projects(:bolete_project).id)}/)
    get(:lookup_project, params: { id: "Bogus" })
    assert_redirected_to(/#{projects_path}/)
    assert_flash_error
    get(:lookup_project, params: { id: "project" })
    # Must test against regex because passed query param borks path match
    assert_redirected_to(%r{/projects})
    assert_flash_warning
  end

  def test_lookup_species_list
    login
    sl_id = species_lists(:first_species_list).id
    get(:lookup_species_list, params: { id: sl_id })
    assert_redirected_to(species_list_path(sl_id))
    get(:lookup_species_list, params: { id: "Mysteries" })
    assert_redirected_to(
      species_list_path(species_lists(:unknown_species_list).id)
    )
    get(:lookup_species_list, params: { id: "species list" })
    # Must test against regex because passed query param borks path match
    assert_redirected_to(%r{/species_lists})
    assert_flash_warning
    get(:lookup_species_list, params: { id: "Flibbertygibbets" })
    assert_redirected_to(species_lists_path)
    assert_flash_error
  end

  def test_lookup_user
    login
    get(:lookup_user, params: { id: rolf.id })
    assert_redirected_to(user_path(rolf.id))
    get(:lookup_user, params: { id: "mary" })
    assert_redirected_to(user_path(mary.id))
    get(:lookup_user, params: { id: "Einstein" })
    assert_redirected_to("/")
    assert_flash_error
    # This caused router to crash in the wild.
    assert_recognizes({ controller: "lookups", action: "lookup_user",
                        id: "I.+G.+Saponov" },
                      "/lookups/lookup_user/I.+G.+Saponov")
  end
end
