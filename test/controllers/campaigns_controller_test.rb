require "test_helper"

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get campaigns_show_url
    assert_response :success
  end
end
