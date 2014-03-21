require File.dirname(__FILE__) + '/../test_helper'

class LinkListBlockTest < ActiveSupport::TestCase

  should 'default describe' do
    assert_not_equal Block.description, LinkListBlock.description
  end

  should 'have field links' do
    l = LinkListBlock.new
    assert_respond_to l, :links
  end
  
  should 'default value of links' do
    l = LinkListBlock.new
    assert_equal [], l.links
  end

  should 'is editable' do
    l = LinkListBlock.new
    assert l.editable?
  end

  should 'list links' do
    l = LinkListBlock.new(:links => [{:name => 'products', :address => '/cat/products'}])
    assert_match /products/, l.content
  end

  should 'remove links with blank fields' do
    l = LinkListBlock.new(:links => [{:name => 'categ', :address => '/address'}, {:name => '', :address => ''}])
    l.save!
    assert_equal [{:name => 'categ', :address => '/address'}], l.links
  end

  should 'replace {profile} with profile identifier' do
    profile = Profile.new(:identifier => 'test_profile')
    l = LinkListBlock.new(:links => [{:name => 'categ', :address => '/{profile}/address'}])
    l.stubs(:owner).returns(profile)
    assert_tag_in_string l.content, :tag => 'a', :attributes => {:href => '/test_profile/address'}
  end

  should 'display options for icons' do
    l = LinkListBlock.new
    l.icons_options.each do |option|
      assert_match(/<span title=\".+\" class=\"icon-.+\" onclick=\"changeIcon\(this, '.+'\)\"><\/span>/, option)
    end
  end

  should 'link with icon' do
    l = LinkListBlock.new
    assert_match /class="icon-save"/, l.link_html({:icon => 'save', :name => 'test', :address => 'test.com'})
  end

  should 'no class without icon' do
    l = LinkListBlock.new
    assert_no_match /class="/, l.link_html({:icon => nil, :name => 'test', :address => 'test.com'})
  end

  should 'not add link to javascript' do
    l = LinkListBlock.new(:links => [{:name => 'link', :address => "javascript:alert('Message test')"}])
    assert_no_match /href="javascript/, l.link_html(l.links.first)
  end

  should 'not add link to onclick' do
    l = LinkListBlock.new(:links => [{:name => 'link', :address => "#\" onclick=\"alert(123456)"}])
    assert_no_tag_in_string l.link_html(l.links.first), :attributes => { :onclick => /.*/ }
  end

  should 'add http in front of incomplete external links' do
    {'/local/link' => '/local/link', 'http://example.org' => 'http://example.org', 'example.org' => 'http://example.org'}.each do |input, output|
      l = LinkListBlock.new(:links => [{:name => 'categ', :address => input}])
      assert_tag_in_string l.content, :tag => 'a', :attributes => {:href => output}
    end
  end

  should 'be able to update display setting' do
    user = create_user('testinguser').person
    box = fast_create(Box, :owner_id => user.id)
    block = LinkListBlock.create!(:display => 'never', :box => box)
    assert block.update_attributes!(:display => 'always')
    block.reload
    assert_equal 'always', block.display
  end

  should 'have options for links target' do
    assert_equivalent LinkListBlock::TARGET_OPTIONS.map {|t|t[1]}, ['_self', '_blank', '_new']
  end

end
