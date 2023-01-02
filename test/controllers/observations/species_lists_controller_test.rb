# frozen_string_literal: true

require("test_helper")

# :manage_species_lists
# NOTE: params change from
# :species_list to :species_list_id
# :observation to :id
module Observations
  class SpeciesListsControllerTest < FunctionalTestCase
    def assigns_exist
      !assigns(:all_lists).empty?
    rescue StandardError
    end

    def test_manage_species_lists
      obs = observations(:coprinus_comatus_obs)
      params = { id: obs.id }
      requires_login(:edit, id: obs.id)

      assert(assigns_exist, "Missing species lists!")
    end

    def test_add_observation_to_species_list
      sp = species_lists(:first_species_list)
      obs = observations(:coprinus_comatus_obs)
      assert_not(sp.observations.member?(obs))
      params = { observation_id: obs.id, id: sp.id, commit: :ADD.l }
      requires_login(:update, params)
      assert_redirected_to(action: :edit, id: obs.id)
      assert(sp.reload.observations.member?(obs))
    end

    def test_add_observation_to_species_list_no_permission
      sp = species_lists(:first_species_list)
      obs = observations(:coprinus_comatus_obs)
      assert_not(sp.observations.member?(obs))
      params = { observation_id: obs.id, id: sp.id, commit: :ADD.l }
      login("dick")
      put(:update, params: params)
      assert_redirected_to(species_list_path(sp.id))
      assert_not(sp.reload.observations.member?(obs))
    end

    def test_remove_observation_from_species_list
      spl = species_lists(:unknown_species_list)
      obs = observations(:minimal_unknown_obs)
      assert(spl.observations.member?(obs))
      params = { observation_id: obs.id, id: spl.id, commit: :REMOVE.l }
      owner = spl.user.login
      assert_not_equal("rolf", owner)

      # Try with non-owner (can't use requires_user since failure is a redirect)
      # effectively fails and gets redirected to show_species_list
      requires_login(:update, params)
      assert_redirected_to(species_list_path(spl.id))
      assert(spl.reload.observations.member?(obs))

      login(owner)
      put(:update, params: params)
      assert_redirected_to(action: :edit, id: obs.id)
      assert_not(spl.reload.observations.member?(obs))
    end

    def test_manage_species_list_with_projects
      proj = projects(:bolete_project)
      spl1 = species_lists(:unknown_species_list)
      spl2 = species_lists(:first_species_list)
      spl3 = species_lists(:another_species_list)
      spl2.user = dick
      spl2.save
      spl2.reload
      obs1 = observations(:detailed_unknown_obs)
      obs2 = observations(:coprinus_comatus_obs)
      assert_obj_arrays_equal([dick], proj.user_group.users)
      assert_obj_arrays_equal([proj], spl1.projects)
      assert_obj_arrays_equal([], spl2.projects)
      assert_obj_arrays_equal([], spl3.projects)
      assert_true(spl1.observations.include?(obs1))
      assert_false(spl1.observations.include?(obs2))
      assert_obj_arrays_equal([], spl2.observations)
      assert_obj_arrays_equal([], spl3.observations)
      assert_users_equal(mary, spl1.user)
      assert_users_equal(dick, spl2.user)
      assert_users_equal(rolf, spl3.user)

      login("dick")
      get(:edit, params: { id: obs1.id })
      assert_select("form[action=?]",
                    observation_species_list_path(observation_id: obs1.id,
                                                  id: spl1.id,
                                                  commit: "remove"),
                    count: 1)
      assert_select("form[action=?]",
                    observation_species_list_path(observation_id: obs1.id,
                                                  id: spl2.id,
                                                  commit: "add"),
                    count: 1)
      assert_select("form[action*=?]",
                    observation_species_list_path(observation_id: obs1.id,
                                                  id: spl3.id,
                                                  commit: "add"),
                    count: 0)

      get(:edit, params: { id: obs2.id })
      puts("spl1 " + spl1.id + "\n")
      puts("spl2 " + spl2.id + "\n")
      puts("spl3 " + spl3.id + "\n")
      # binding.break
      assert_select("form[action=?]",
                    observation_species_list_path(observation_id: obs1.id,
                                                  id: spl1.id,
                                                  commit: "add"),
                    count: 1)
      assert_select("form[action=?]",
                    observation_species_list_path(observation_id: obs1.id,
                                                  id: spl2.id,
                                                  commit: "add"),
                    count: 1)
      assert_select("form[action*=?]",
                    observation_species_list_path(observation_id: obs1.id,
                                                  id: spl3.id,
                                                  commit: "add"),
                    count: 0)

      put(:update,
          params: { observation_id: obs2.id, id: spl1.id, commit: "add" })
      assert_redirected_to(action: :edit, id: obs2.id)
      assert_true(spl1.reload.observations.include?(obs2))

      put(:update,
          params: { observation_id: obs2.id, id: spl1.id, commit: "remove" })
      assert_redirected_to(action: :edit, id: obs2.id)
      assert_false(spl1.reload.observations.include?(obs2))
    end
  end
end
