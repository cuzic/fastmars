require File.dirname(__FILE__) + '/../../test_helper'
require 'api/search_controller'

# Re-raise errors caught by the controller.
class Api::SearchController; def rescue_action(e) raise e end; end

class Api::SearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = Api::SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
