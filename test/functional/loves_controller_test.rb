require 'test_helper'

class LovesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:loves)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create love" do
    assert_difference('Love.count') do
      post :create, :love => { }
    end

    assert_redirected_to love_path(assigns(:love))
  end

  test "should show love" do
    get :show, :id => loves(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => loves(:one).id
    assert_response :success
  end

  test "should update love" do
    put :update, :id => loves(:one).id, :love => { }
    assert_redirected_to love_path(assigns(:love))
  end

  test "should destroy love" do
    assert_difference('Love.count', -1) do
      delete :destroy, :id => loves(:one).id
    end

    assert_redirected_to loves_path
  end
end
