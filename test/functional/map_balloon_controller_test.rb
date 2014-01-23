require File.dirname(__FILE__) + '/../test_helper'
require 'map_balloon_controller'


# Re-raise errors caught by the controller.
class MapBalloonController; def rescue_action(e) raise e end; end

class MapBalloonControllerTest < ActionController::TestCase

  def setup
    @controller = MapBalloonController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @profile = create_user('test_profile').person
    login_as(@profile.identifier)
  end

  should 'find product to show' do
    prod = Product.create!(:name => 'Product1', :product_category_id => fast_create(ProductCategory).id,
      :profile_id => fast_create(Enterprise).id)
    get :product, :id => prod.id
    assert_equal prod, assigns(:product)
  end

  should 'find person to show' do
    pers = Person.create!(:name => 'Person1', :user_id => fast_create(User).id, :identifier => 'pers1')
    get :person, :id => pers.id
    assert_equal pers, assigns(:profile)
  end

  should 'find enterprise to show' do
    ent = Enterprise.create!(:name => 'Enterprise1', :identifier => 'ent1')
    get :enterprise, :id => ent.id
    assert_equal ent, assigns(:profile)
  end

  should 'find community to show' do
    comm = Community.create!(:name => 'Community1', :identifier => 'comm1')
    get :community, :id => comm.id
    assert_equal comm, assigns(:profile)
  end
end
