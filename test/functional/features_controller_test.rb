require File.dirname(__FILE__) + '/../test_helper'
require 'features_controller'

# Re-raise errors caught by the controller.
class FeaturesController; def rescue_action(e) raise e end; end

class FeaturesControllerTest < ActionController::TestCase

  all_fixtures 
  def setup
    @controller = FeaturesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(create_admin_user(Environment.find(2)))
  end
  
  def test_local_files_reference
    assert_local_files_reference
  end
  
  def test_valid_xhtml
    assert_valid_xhtml
  end
  
  def test_listing_features
    uses_host 'anhetegua.net'
    get :index
    assert_template 'index'
    Environment.available_features.each do |feature, text|
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "environment[enabled_features][]", :value => feature})
    end
  end

  should 'list features alphabetically' do
    uses_host 'anhetegua.net'
    Environment.expects(:available_features).returns({"c_feature" => "Starting with C", "a_feature" => "Starting with A", "b_feature" => "Starting with B"}).at_least_once
    get :index
    assert_equal [['a_feature', 'Starting with A'], ['b_feature', 'Starting with B'], ['c_feature', 'Starting with C']], assigns(:features)
  end

  def test_updates_enabled_features
    uses_host 'anhetegua.net'
    post :update, :environment => { :enabled_features => [ 'feature1', 'feature2' ] }
    assert_redirected_to :action => 'index'
    assert_kind_of String, session[:notice]
    v = Environment.find(environments(:anhetegua_net).id)
    assert v.enabled?('feature2')
    assert v.enabled?('feature2') 
    assert !v.enabled?('feature3')
  end

  def test_update_disable_all
    uses_host 'anhetegua.net'
    post :update # no features
    assert_redirected_to :action => 'index'
    assert_kind_of String, session[:notice]
    v = Environment.find(environments(:anhetegua_net).id)
    assert !v.enabled?('feature1')
    assert !v.enabled?('feature2')
    assert !v.enabled?('feature3')
  end

  def test_update_no_post
    uses_host 'anhetegua.net'
    get :update
    assert_redirected_to :action => 'index'
  end

  def test_updates_organization_approval_method
    uses_host 'anhetegua.net'
    post :update, :environment => { :organization_approval_method => 'region' }
    assert_redirected_to :action => 'index'
    assert_kind_of String, session[:notice]
    v = Environment.find(environments(:anhetegua_net).id)
    assert_equal :region, v.organization_approval_method
  end

  def test_should_mark_current_organization_approval_method_in_view
    uses_host 'anhetegua.net'
    Environment.find(environments(:anhetegua_net).id).update_attributes(:organization_approval_method => :region)

    post :index

    assert_tag :tag => 'select', :attributes => { :name => 'environment[organization_approval_method]' }, :descendant => { :tag => 'option', :attributes => { :value => 'region', :selected => true } }
  end

  should 'list possible person fields' do
    uses_host 'anhetegua.net'
    Person.expects(:fields).returns(['cell_phone', 'comercial_phone']).at_least_once
    get :manage_fields
    assert_template 'manage_fields'
    Person.fields.each do |field|
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "person_fields[#{field}][active]"})
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "person_fields[#{field}][required]"})
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "person_fields[#{field}][signup]"})
    end
  end

  should 'update custom_person_fields' do
    uses_host 'anhetegua.net'
    e = Environment.find(2)
    Person.expects(:fields).returns(['cell_phone', 'comercial_phone']).at_least_once

    post :manage_person_fields, :person_fields => { :cell_phone => {:active => true, :required => true }}
    assert_redirected_to :action => 'manage_fields'
    e.reload
    assert_equal true, e.custom_person_fields['cell_phone']['active']
    assert_equal true, e.custom_person_fields['cell_phone']['required']
  end

  should 'list possible enterprise fields' do
    uses_host 'anhetegua.net'
    Enterprise.expects(:fields).returns(['contact_person', 'contact_email']).at_least_once
    get :manage_fields
    assert_template 'manage_fields'
    Enterprise.fields.each do |field|
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "enterprise_fields[#{field}][active]"})
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "enterprise_fields[#{field}][required]"})
    end
  end

  should 'update custom_enterprise_fields' do
    uses_host 'anhetegua.net'
    e = Environment.find(2)
    Enterprise.expects(:fields).returns(['contact_person', 'contact_email']).at_least_once

    post :manage_enterprise_fields, :enterprise_fields => { :contact_person => {:active => true, :required => true }}
    assert_redirected_to :action => 'manage_fields'
    e.reload
    assert_equal true, e.custom_enterprise_fields['contact_person']['active']
    assert_equal true, e.custom_enterprise_fields['contact_person']['required']
  end

  should 'list possible community fields' do
    uses_host 'anhetegua.net'
    Community.expects(:fields).returns(['contact_person', 'contact_email']).at_least_once
    get :manage_fields
    assert_template 'manage_fields'
    Community.fields.each do |field|
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "community_fields[#{field}][active]"})
      assert_tag(:tag => 'input', :attributes => { :type => 'checkbox', :name => "community_fields[#{field}][required]"})
    end
  end

  should 'update custom_community_fields' do
    uses_host 'anhetegua.net'
    e = Environment.find(2)
    Community.expects(:fields).returns(['contact_person', 'contact_email']).at_least_once

    post :manage_community_fields, :community_fields => { :contact_person => {:active => true, :required => true }}
    assert_redirected_to :action => 'manage_fields'
    e.reload
    assert_equal true, e.custom_community_fields['contact_person']['active']
    assert_equal true, e.custom_community_fields['contact_person']['required']
  end

end
