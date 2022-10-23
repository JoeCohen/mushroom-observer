# frozen_string_literal: true

require "test_helper"

class VisualGroupsControllerTest < FunctionalTestCase
  setup do
    @visual_group = visual_groups(:visual_group_one)
  end

  test "should get index" do
    login
    get(:index, params: { visual_model_id: @visual_group.visual_model_id })
    assert_response :success
  end

  test "should get new" do
    login
    get(:new, params: { visual_model_id: @visual_group.visual_model_id })
    assert_response :success
  end

  test "should create visual_group" do
    login
    assert_difference('VisualGroup.count') do
      post(:create, params: {
             visual_model_id: @visual_group.visual_model_id,
             visual_group: {
               visual_model_id: @visual_group.visual_model_id,
               name: @visual_group.name,
               approved: @visual_group.approved
             }
           })
    end
    assert_redirected_to visual_model_visual_groups_url(@visual_group.visual_model, VisualGroup.last)
  end

  test "should show visual_group" do
    login
    get(:show, params: {
          id: visual_groups(:visual_group_one).id,
          visual_model_id: @visual_group.visual_model_id
        })
    assert_response :success
  end

  # test "should get edit" do
  #   get edit_visual_group_url(@visual_group)
  #   assert_response :success
  # end

  # test "should update visual_group" do
  #   patch visual_group_url(@visual_group), params: { visual_group:
  # { name: @visual_group.name,
  # reviewed: @visual_group.reviewed } }
  #   assert_redirected_to visual_group_url(@visual_group)
  # end

  # test "should destroy visual_group" do
  #   assert_difference('VisualGroup.count', -1) do
  #     delete visual_group_url(@visual_group)
  #   end

  #   assert_redirected_to visual_groups_url
  # end
end
