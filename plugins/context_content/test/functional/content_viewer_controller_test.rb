require 'test_helper'

class ContentViewerController
  append_view_path File.join(File.dirname(__FILE__) + '/../../views')
  def rescue_action(e)
    raise e
  end
end

class ContentViewerControllerTest < ActionController::TestCase

  def setup
    @profile = fast_create(Community)
    @page = fast_create(Folder, :profile_id => @profile.id)

    box = Box.create!(:owner => @profile)
    @block = ContextContentPlugin::ContextContentBlock.new(:box => box)
    @block.types = ['TinyMceArticle']
    @block.limit = 1
    @block.save!
  end

  should 'do not display context content block if it has no contents' do
    get :view_page, @page.url
    assert_no_tag 'div', :attributes => {:id => "context_content_#{@block.id}", :class => 'contents'}
    assert_no_tag 'div', :attributes => {:id => "context_content_more_#{@block.id}", :class => 'more_button'}
  end

  should 'display context content block if it has contents' do
    article = fast_create(TinyMceArticle, :parent_id => @page.id, :profile_id => @profile.id, :name => 'article1')
    get :view_page, @page.url
    assert_tag 'div', :attributes => {:id => "context_content_#{@block.id}", :class => 'contents'}
    assert_no_tag 'div', :attributes => {:id => "context_content_more_#{@block.id}", :class => 'more_button'}, :descendant => {:tag => 'a'}
    assert_match /article1/, @response.body
  end

  should 'display context content block with pagination' do
    article1 = fast_create(TinyMceArticle, :parent_id => @page.id, :profile_id => @profile.id)
    article2 = fast_create(TinyMceArticle, :parent_id => @page.id, :profile_id => @profile.id)
    get :view_page, @page.url
    assert_tag 'div', :attributes => {:id => "context_content_#{@block.id}", :class => 'contents'}
    assert_tag 'div', :attributes => {:id => "context_content_more_#{@block.id}", :class => 'more_button'}, :descendant => {:tag => 'a', :attributes => {:class => 'button icon-button icon-left disabled'} }
    assert_tag 'div', :attributes => {:id => "context_content_more_#{@block.id}", :class => 'more_button'}, :descendant => {:tag => 'a', :attributes => {:class => 'button icon-button icon-right'} }
  end

end
