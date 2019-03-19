require 'test_helper'

class MusicReportsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:music_reports)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create music_reports" do
    assert_difference('MusicReports.count') do
      post :create, :music_reports => { }
    end

    assert_redirected_to music_reports_path(assigns(:music_reports))
  end

  test "should show music_reports" do
    get :show, :id => music_reports(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => music_reports(:one).id
    assert_response :success
  end

  test "should update music_reports" do
    put :update, :id => music_reports(:one).id, :music_reports => { }
    assert_redirected_to music_reports_path(assigns(:music_reports))
  end

  test "should destroy music_reports" do
    assert_difference('MusicReports.count', -1) do
      delete :destroy, :id => music_reports(:one).id
    end

    assert_redirected_to music_reports_path
  end
end
