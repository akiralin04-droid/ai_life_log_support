require "test_helper"

class Admin::CampaignsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_campaigns_index_url
    assert_response :success
  end

  test "should get new" do
    get admin_campaigns_new_url
    assert_response :success
  end

  test "should get edit" do
    get admin_campaigns_edit_url
    assert_response :success
  end
end
