require File.dirname(__FILE__) + '/../test_helper'

class ProfileDesignController
  append_view_path File.join(File.dirname(__FILE__) + '/../../views')
  def rescue_action(e)
    raise e
  end
end

class ProfileDesignControllerTest < ActionController::TestCase

  def setup
    @environment = Environment.default
    @environment.enabled_plugins = ['BreadcrumbsPlugin']
    @environment.save!

    @profile = fast_create(Community, :environment_id => @environment.id)
    @page = fast_create(Folder, :profile_id => @profile.id)

    box = Box.create!(:owner => @profile)
    @block = BreadcrumbsPlugin::ContentBreadcrumbsBlock.create!(:box => box)

    user = create_user('testinguser')
    @profile.add_admin(user.person)
    login_as(user.login)
  end

  should 'be able to edit breadcrumbs block' do
    get :edit, :id => @block.id, :profile => @profile.identifier
    assert_tag :tag => 'input', :attributes => { :id => 'block_title' }
    assert_tag :tag => 'input', :attributes => { :id => 'block_show_cms_action' }
    assert_tag :tag => 'input', :attributes => { :id => 'block_show_profile' }
  end

  should 'be able to save breadcrumbs block' do
    get :edit, :id => @block.id, :profile => @profile.identifier
    post :save, :id => @block.id, :profile => @profile.identifier, :block => {:title => 'breadcrumbs', :show_cms_action => false, :show_profile => false}
    @block.reload
    assert_equal 'breadcrumbs', @block.title
    assert !@block.show_profile
    assert !@block.show_cms_action
  end

end
