require 'test_helper'

class ProfileDesignController
  append_view_path File.join(File.dirname(__FILE__) + '/../../views')
  def rescue_action(e)
    raise e
  end
end

class ProfileDesignControllerTest < ActionController::TestCase

  def setup
    Environment.delete_all
    @environment = Environment.create(:name => 'testenv', :is_default => true)
    @environment.enabled_plugins = ['ContextContentPlugin']
    @environment.save!

    @profile = fast_create(Community, :environment_id => @environment.id)
    @page = fast_create(Folder, :profile_id => @profile.id)

    box = Box.create!(:owner => @profile)
    @block = ContextContentPlugin::ContextContentBlock.new(:box => box)
    @block.types = ['TinyMceArticle']
    @block.limit = 1
    @block.save!

    user = create_user('testinguser')
    @profile.add_admin(user.person)
    login_as(user.login)
  end

  should 'be able to edit context content block' do
    get :edit, :id => @block.id, :profile => @profile.identifier
    assert_tag :tag => 'input', :attributes => { :id => 'block_title' }
    assert_tag :tag => 'input', :attributes => { :id => 'block_show_image' }
    assert_tag :tag => 'input', :attributes => { :id => 'block_show_name' }
    assert_tag :tag => 'input', :attributes => { :id => 'block_show_parent_content' }
    assert_tag :tag => 'input', :attributes => { :id => 'block_types' }
  end

  should 'be able to save TrackListBlock' do
    @block.show_image = false
    @block.show_name = false
    @block.show_parent_content = false
    @block.save!
    get :edit, :id => @block.id, :profile => @profile.identifier
    post :save, :id => @block.id, :block => {:title => 'context', :show_image => '0', :show_name => '0', :show_parent_content => '0', :types => ['TinyMceArticle', '', nil, 'Folder'] }, :profile => @profile.identifier
    @block.reload
    assert_equal 'context', @block.title
    assert !@block.show_image && !@block.show_name && !@block.show_parent_content
    assert_equal ['TinyMceArticle', 'Folder'], @block.types
  end

end
