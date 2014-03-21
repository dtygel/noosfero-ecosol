require 'test_helper'

class ContainerBlockPluginMyprofileControllerTest < ActionController::TestCase

  def setup
    user = create_user('testinguser')
    login_as(user.login)

    @profile = fast_create(Community)
    @profile.add_admin(user.person)
    @box = Box.new(:owner => @profile)

    @block = ContainerBlockPlugin::ContainerBlock.create!(:box => @box)
    @child1 = Block.create!(:box => @block.container_box)
    @child2 = Block.create!(:box => @block.container_box)
  end

  should 'save widths of container block children' do
    xhr :post, :saveWidths, :profile => @profile.identifier, :id => @block.id, :widths => "#{@child1.id},100|#{@child2.id},200"
    assert_response 200
    assert_equal 'Block successfully saved.', @response.body
    @block.reload
    assert_equal 100, @block.child_width(@child1.id)
    assert_equal 200, @block.child_width(@child2.id)
  end

end
