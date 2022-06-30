# frozen_string_literal: true

require("test_helper")

# Controller tests for search pages
class SearchesControllerTest < FunctionalTestCase
  def test_advanced_search_form
    login
    [Name, Image, Observation].each do |model|
      post(
        "advanced_search_form",
        params: {
          search: {
            name: "Don't know",
            user: "myself",
            model: model.name.underscore,
            content: "Long pink stem and small pink cap",
            location: "Eastern Oklahoma"
          },
          commit: "Search"
        }
      )
      assert_response(:redirect)
      if model.controller_normalized?
        assert_match(%r{#{model.pluralize}_path},
          redirect_to_url)
      else
        assert_match(%r{#{model.show_controller}/advanced_search},
                    redirect_to_url)
      end
    end
  end

  def test_advanced_search_content_filters
    login
    # Make sure all the right buttons and fields are present.
    get(:advanced_search_form)
    assert_select("input[type=radio]#content_filter_has_images_yes")
    assert_select("input[type=radio]#content_filter_has_images_no")
    assert_select("input[type=radio]#content_filter_has_images_")
    assert_select("input[type=radio]#content_filter_has_specimen_yes")
    assert_select("input[type=radio]#content_filter_has_specimen_no")
    assert_select("input[type=radio]#content_filter_has_specimen_")
    assert_select("input[type=radio]#content_filter_lichen_yes")
    assert_select("input[type=radio]#content_filter_lichen_no")
    assert_select("input[type=radio]#content_filter_lichen_")
    assert_select("input[type=text]#content_filter_region")
    assert_select("input[type=text]#content_filter_clade")

    params = {
      search: {
        model: "observation",
        user: "rolf"
      },
      content_filter_has_images: "",
      content_filter_has_specimen: "yes",
      content_filter_lichen: "no",
      content_filter_region: "California",
      content_filter_clade: ""
    }
    post(:advanced_search_form, params: params)
    query = QueryRecord.last.query
    assert_equal("", query.params[:has_images])
    assert_true(query.params[:has_specimen])
    assert_false(query.params[:lichen])
    assert_equal(["California"], query.params[:region])
    assert_equal("", query.params[:clade])
  end

  def test_pattern_search
    login
    params = { search: { pattern: "12", type: :observation } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :observations, action: :index,
                         pattern: "12")

    params = { search: { pattern: "34", type: :image } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :image, action: :image_search,
                         pattern: "34")

    params = { search: { pattern: "56", type: :name } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :name, action: :name_search,
                         pattern: "56")

    params = { search: { pattern: "78", type: :location } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :location, action: :location_search,
                         pattern: "78")

    params = { search: { pattern: "90", type: :comment } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :comment, action: :comment_search,
                         pattern: "90")

    params = { search: { pattern: "12", type: :species_list } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :species_list,
                         action: :species_list_search,
                         pattern: "12")

    params = { search: { pattern: "34", type: :user } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(users_path(pattern: "34"))

    stub_request(:any, /google.com/)
    pattern =  "hexiexiva"
    params = { search: { pattern: pattern, type: :google } }
    target =
      "https://google.com/search?q=site%3Amushroomobserver.org+#{pattern}"
    get_with_dump(:pattern_search, params)
    assert_redirected_to(target)

    params = { search: { pattern: "", type: :google } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to("/")

    params = { search: { pattern: "x", type: :nonexistent_type } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to("/")

    params = { search: { pattern: "", type: :observation } }
    get_with_dump(:pattern_search, params)
    assert_redirected_to(controller: :observations, action: :index)

    # Make sure this redirects to the index that lists all herbaria,
    # rather than the index that lists query results.
    params = { search: { pattern: "", type: :herbarium } }
    get(:pattern_search, params: params)
    assert_redirected_to(herbaria_path(flavor: :all))
  end
end