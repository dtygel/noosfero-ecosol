require File.dirname(__FILE__) + '/../test_helper'
require 'profile_controller'

# Re-raise errors caught by the controller.
class ProfileController; def rescue_action(e) raise e end; end

class ProfileControllerTest < ActionController::TestCase
  def setup
    @controller = ProfileController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @profile = create_user('testuser').person
  end
  attr_reader :profile

  def test_local_files_reference
    assert_local_files_reference
  end
  
  def test_valid_xhtml
    assert_valid_xhtml
  end
  
  noosfero_test :profile => 'testuser'

  should 'list friends' do
    get :friends

    assert_response :success
    assert_template 'friends'
    assert_kind_of Array, assigns(:friends)
  end

  should 'point to manage friends in user is seeing his own friends' do
    login_as('testuser')
    get :friends
    assert_tag :tag => 'a', :attributes => { :href => '/myprofile/testuser/friends' }
  end

  should 'not point to manage friends of other users' do
    create_user('ze')
    login_as('ze')
    get :friends
    assert_no_tag :tag => 'a', :attributes => { :href => '/myprofile/testuser/friends' }
  end

  should 'list communities' do
    get :communities

    assert_response :success
    assert_template 'communities'
    assert_kind_of Array, assigns(:communities)
  end

  should 'list enterprises' do
    get :enterprises

    assert_response :success
    assert_template 'enterprises'
    assert_kind_of Array, assigns(:enterprises)
  end

  should 'list members (for organizations)' do
    get :members

    assert_response :success
    assert_template 'members'
    assert_kind_of Array, assigns(:members)
  end
  
  should 'list favorite enterprises' do
    get :favorite_enterprises

    assert_response :success
    assert_template 'favorite_enterprises'
    assert_kind_of Array, assigns(:favorite_enterprises)
  end

  should 'not render any template when joining community due to Ajax request' do
    community = Community.create!(:name => 'my test community')
    login_as(@profile.identifier)

    get :join, :profile => community.identifier
    assert_response :success
    assert_template nil
    assert_no_tag :tag => 'html'
  end

  should 'actually add friend' do
    login_as(@profile.identifier)
    person = fast_create(Person)
    assert_difference AddFriend, :count do
      post :add, :profile => person.identifier
    end
  end

  should 'not show enterprises link to enterprise' do
    ent = fast_create(Enterprise, :identifier => 'test_enterprise1', :name => 'Test enteprise1')
    get :index, :profile => ent.identifier
    assert_no_tag :tag => 'a', :content => 'Enterprises', :attributes => { :href => /profile\/#{ent.identifier}\/enterprises$/ }
  end

  should 'not show members link to person' do
    person = create_user('person_1').person
    get :index, :profile => person.identifier
    assert_no_tag :tag => 'a', :content => 'Members', :attributes => { :href => /profile\/#{person.identifier}\/members$/ }
  end

  should 'show friends link to person' do
    person = create_user('person_1').person
    get :index, :profile => person.identifier
    assert_tag :tag => 'a', :content => /#{profile.friends.count}/, :attributes => { :href => /profile\/#{person.identifier}\/friends$/ }
  end

  should 'display tag for profile' do
    @profile.articles.create!(:name => 'testarticle', :tag_list => 'tag1')

    get :content_tagged, :profile => @profile.identifier, :id => 'tag1'
    assert_tag :tag => 'a', :attributes => { :href => /testuser\/testarticle$/ }
  end

  should 'link to the same tag but for whole environment' do
    @profile.articles.create!(:name => 'testarticle', :tag_list => 'tag1')
    get :content_tagged, :profile => @profile.identifier, :id => 'tag1'

    assert_tag :tag => 'a', :attributes => { :href => '/tag/tag1' }, :content => 'See content tagged with "tag1" in the entire site'
  end

  should 'show a link to own control panel' do
    login_as(@profile.identifier)
    get :index, :profile => @profile.identifier
    assert_tag :tag => 'a', :content => 'Control panel'
  end

  should 'show a link to own control panel in my-network-block if is a group' do
    login_as(@profile.identifier)
    community = Community.create!(:name => 'my test community')
    community.blocks.each{|i| i.destroy}
    community.boxes[0].blocks << MyNetworkBlock.new
    community.add_admin(@profile)
    get :index, :profile => community.identifier
    assert_tag :tag => 'a', :content => 'Control panel'
  end

  should 'not show a link to others control panel' do
    login_as(@profile.identifier)
    other = create_user('person_1').person
    other.blocks.each{|i| i.destroy}
    other.boxes[0].blocks << ProfileInfoBlock.new
    get :index, :profile => other.identifier
    assert_no_tag :tag => 'ul', :attributes => { :class => 'profile-info-data' }, :descendant => { :tag => 'a', :content => 'Control panel' }
  end

  should 'show a link to control panel if user has profile_editor permission and is a group' do
    login_as(@profile.identifier)
    community = Community.create!(:name => 'my test community')
    community.add_admin(@profile)
    get :index, :profile => community.identifier
    assert_tag :tag => 'a', :attributes => { :href => /\/myprofile\/\{login\}/ }, :content => 'Control panel'
  end

  should 'show create community in own profile' do
    login_as(@profile.identifier)
    get :communities, :profile => @profile.identifier
    assert_tag :tag => 'a', :child => { :tag => 'span', :content => 'Create a new community' }
  end

  should 'not show create community on profile of other users' do
    login_as(@profile.identifier)
    person = create_user('person_1').person
    get :communities, :profile => person.identifier
    assert_no_tag :tag => 'a', :child => { :tag => 'span', :content => 'Create a new community' }
  end

  should 'not show Leave This Community button for non-registered users' do
    community = Community.create!(:name => 'my test community')
    community.boxes.first.blocks << block = ProfileInfoBlock.create!
    get :profile_info, :profile => community.identifier, :block_id => block.id
    assert_no_match /\/profile\/#{@profile.identifier}\/leave/, @response.body
  end

  should 'check access before displaying profile' do
    Person.any_instance.expects(:display_info_to?).with(anything).returns(false)
    @profile.visible = false
    @profile.save

    get :index, :profile => @profile.identifier
    assert_response 403
  end

  should 'display template profiles' do
    Person.any_instance.expects(:display_info_to?).with(anything).returns(false)
    @profile.visible = false
    @profile.is_template = true
    @profile.save

    get :index, :profile => @profile.identifier
    assert_response :success
  end


  should 'display add friend button' do
    @profile.user.activate
    login_as(@profile.identifier)
    friend = create_user_full('friendtestuser').person
    friend.user.activate
    friend.boxes.first.blocks << block = ProfileInfoBlock.create!
    get :profile_info, :profile => friend.identifier, :block_id => block.id
    assert_match /Add friend/, @response.body
  end

  should 'not display add friend button if user already request friendship' do
    login_as(@profile.identifier)
    friend = create_user_full('friendtestuser').person
    friend.boxes.first.blocks << block = ProfileInfoBlock.create!
    AddFriend.create!(:person => @profile, :friend => friend)
    get :profile_info, :profile => friend.identifier, :block_id => block.id
    assert_no_match /Add friend/, @response.body
  end

  should 'not display add friend button if user already friend' do
    login_as(@profile.identifier)
    friend = create_user_full('friendtestuser').person
    friend.boxes.first.blocks << block = ProfileInfoBlock.create!
    @profile.add_friend(friend)
    @profile.friends.reload
    assert @profile.is_a_friend?(friend)
    get :profile_info, :profile => friend.identifier, :block_id => block.id
    assert_no_match /Add friend/, @response.body
  end

  should 'show message for disabled enterprise' do
    login_as(@profile.identifier)
    ent = fast_create(Enterprise, :name => 'my test enterprise', :identifier => 'my-test-enterprise', :enabled => false)
    get :index, :profile => ent.identifier
    assert_tag :tag => 'div', :attributes => { :id => 'profile-disabled' }, :content => /#{Environment.default.message_for_disabled_enterprise}/
  end

  should 'not show message for disabled enterprise to non-enterprises' do
    login_as(@profile.identifier)
    @profile.enabled = false; @profile.save!
    get :index, :profile => @profile.identifier
    assert_no_tag :tag => 'div', :attributes => { :id => 'profile-disabled' }, :content => Environment.default.message_for_disabled_enterprise
  end

  should 'not show message for disabled enterprise if there is a block for it' do
    login_as(@profile.identifier)
    ent = fast_create(Enterprise, :name => 'my test enterprise', :identifier => 'my-test-enterprise', :enabled => false)
    ent.boxes << Box.new
    ent.boxes[0].blocks << DisabledEnterpriseMessageBlock.new
    ent.save
    get :index, :profile => ent.identifier
    assert_no_tag :tag => 'div', :attributes => {:class => 'blocks'}, :descendant => { :tag => 'div', :attributes => { :id => 'profile-disabled' }}
  end

  should 'display "Products" link for enterprise' do
    ent = fast_create(Enterprise, :name => 'my test enterprise', :identifier => 'my-test-enterprise', :enabled => false)

    get :index, :profile => 'my-test-enterprise'
    assert_tag :tag => 'a', :attributes => { :href => '/catalog/my-test-enterprise'}, :content => /Products\/Services/
  end

  should 'not display "Products" link for enterprise if environment do not let' do
    env = Environment.default
    env.enable('disable_products_for_enterprises')
    env.save!
    ent = fast_create(Enterprise, :name => 'my test enterprise', :identifier => 'my-test-enterprise', :enabled => false, :environment_id => env.id)

    get :index, :profile => 'my-test-enterprise'
    assert_no_tag :tag => 'a', :attributes => { :href => '/catalog/my-test-enterprise'}, :content => /Products\/Services/
  end


  should 'not display "Products" link for people' do
    get :index, :profile => 'ze'
    assert_no_tag :tag => 'a', :attributes => { :href => '/catalog/my-test-enterprise'}, :content => /Products\/Services/
  end

  should 'list top level articles in sitemap' do
    get :sitemap, :profile => 'testuser'
    assert_equal @profile.top_level_articles, assigns(:articles)
  end

  should 'list tags' do
    Person.any_instance.stubs(:article_tags).returns({ 'one' => 1, 'two' => 2})
    get :tags, :profile => 'testuser'

    assert_tag :tag => 'div', :attributes => { :class => /main-block/ }, :descendant => { :tag => 'a', :attributes => { :href => '/profile/testuser/tags/one'} }
    assert_tag :tag => 'div', :attributes => { :class => /main-block/ }, :descendant => { :tag => 'a', :attributes => { :href => '/profile/testuser/tags/two'} }
  end

  should 'not show e-mail for non friends on profile page' do
    p1 = create_user('tusr1').person
    p2 = create_user('tusr2', :email => 't2@t2.com').person
    login_as 'tusr1'

    get :index, :profile => 'tusr2'
    assert_no_tag :content => /t2@t2.com/
  end

  should 'display contact us for enterprises' do
    ent = Enterprise.create!(:name => 'my test enterprise', :identifier => 'my-test-enterprise')
    ent.boxes.first.blocks << block = ProfileInfoBlock.create!
    get :profile_info, :profile => 'my-test-enterprise', :block_id => block.id
    assert_match /\/contact\/my-test-enterprise\/new/, @response.body
  end

  should 'not display contact us for non-enterprises' do
    @profile.boxes.first.blocks << block = ProfileInfoBlock.create!
    get :profile_info, :profile => @profile.identifier, :block_id => block.id
    assert_no_match /\/contact\/#{@profile.identifier}\/new/, @response.body
  end

  should 'display contact us only if enabled' do
    ent = Enterprise.create! :name => 'my test enterprise', :identifier => 'my-test-enterprise'
    ent.boxes.first.blocks << block = ProfileInfoBlock.create!
    ent.update_attribute(:enable_contact_us, false)
    get :profile_info, :profile => 'my-test-enterprise', :block_id => block.id
    assert_no_match /\/contact\/my-test-enterprise\/new/, @response.body
  end
  
  should 'display contact button only if friends' do
    friend = create_user_full('friend_user').person
    friend.user.activate
    friend.boxes.first.blocks << block = ProfileInfoBlock.create!
    @profile.add_friend(friend)
    env = Environment.default
    env.disable('disable_contact_person')
    env.save!
    login_as(@profile.identifier)
    get :profile_info, :profile => friend.identifier, :block_id => block.id
    assert_match /\/contact\/#{friend.identifier}\/new/, @response.body
  end

  should 'not display contact button if no friends' do
    nofriend = create_user_full('no_friend').person
    nofriend.boxes.first.blocks << block = ProfileInfoBlock.create!
    login_as(@profile.identifier)
    get :profile_info, :profile => nofriend.identifier, :block_id => block.id
    assert_no_match /\/contact\/#{nofriend.identifier}\/new/, @response.body
  end

  should 'display contact button only if friends and its enable in environment' do
    friend = create_user_full('friend_user').person
    friend.user.activate
    friend.boxes.first.blocks << block = ProfileInfoBlock.create!
    env = Environment.default
    env.disable('disable_contact_person')
    env.save!
    @profile.add_friend(friend)
    login_as(@profile.identifier)
    get :profile_info, :profile => friend.identifier, :block_id => block.id
    assert_match /\/contact\/#{friend.identifier}\/new/, @response.body
  end

  should 'not display contact button if friends and its disable in environment' do
    friend = create_user_full('friend_user').person
    friend.boxes.first.blocks << block = ProfileInfoBlock.create!
    env = Environment.default
    env.enable('disable_contact_person')
    env.save!
    @profile.add_friend(friend)
    login_as(@profile.identifier)
    get :profile_info, :profile => friend.identifier, :block_id => block.id
    assert_no_match /\/contact\/#{friend.identifier}\/new/, @response.body
  end

  should 'display contact button for community if its enable in environment' do
    env = Environment.default
    community = Community.create!(:name => 'my test community', :environment => env)
    community.boxes.first.blocks << block = ProfileInfoBlock.create!
    env.disable('disable_contact_community')
    env.save!
    community.add_member(@profile)
    login_as(@profile.identifier)
    get :profile_info, :profile => community.identifier, :block_id => block.id
    assert_match /\/contact\/#{community.identifier}\/new/, @response.body
  end

  should 'not display contact button for community if its disable in environment' do
    env = Environment.default
    community = Community.create!(:name => 'my test community', :environment => env)
    community.boxes.first.blocks << block = ProfileInfoBlock.create!
    env.enable('disable_contact_community')
    env.save!
    community.add_member(@profile)
    login_as(@profile.identifier)
    get :profile_info, :profile => community.identifier, :block_id => block.id
    assert_no_match /\/contact\/#{community.identifier}\/new/, @response.body
  end

  should 'actually join profile' do
    community = Community.create!(:name => 'my test community')
    login_as @profile.identifier
    post :join, :profile => community.identifier

    assert_response :success
    assert_template nil

    profile = Profile.find(@profile.id)
    assert profile.memberships.include?(community), 'profile should be actually added to the community'
  end

  should 'create task when join to closed organization with members' do
    community = fast_create(Community)
    community.update_attribute(:closed, true)
    admin = fast_create(Person)
    community.add_member(admin)

    login_as profile.identifier
    assert_difference AddMember, :count do
      post :join, :profile => community.identifier
    end
  end

  should 'not create task when join to closed and empty organization' do
    community = fast_create(Community)
    community.update_attribute(:closed, true)

    login_as profile.identifier
    assert_no_difference AddMember, :count do
      post :join, :profile => community.identifier
    end
  end

  should 'require login to join community' do
    community = Community.create!(:name => 'my test community', :closed => true)
    get :join, :profile => community.identifier

    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should 'actually leave profile' do
    community = fast_create(Community)
    admin = fast_create(Person)
    community.add_member(admin)

    community.add_member(profile)
    assert_includes profile.memberships, community

    login_as(profile.identifier)
    post :leave, :profile => community.identifier

    profile = Profile.find(@profile.id)
    assert_not_includes profile.memberships, community
  end

  should 'require login to leave community' do
    community = Community.create!(:name => 'my test community')
    get :leave, :profile => community.identifier

    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should 'not leave if is last admin' do
    community = fast_create(Community)

    community.add_admin(profile)
    assert_includes profile.memberships, community

    login_as(profile.identifier)
    post :leave, :profile => community.identifier

    profile.reload
    assert_response :success
    assert_match(/last_admin/, @response.body)
    assert_includes profile.memberships, community
  end

  should 'store location before login when request join via get not logged' do
    community = Community.create!(:name => 'my test community')

    @request.expects(:referer).returns("/profile/#{community.identifier}")

    get :join, :profile => community.identifier

    assert_equal "/profile/#{community.identifier}", @request.session[:previous_location]
  end

  should 'redirect to location before login after join community' do
    community = Community.create!(:name => 'my test community')

    @request.expects(:referer).returns("/profile/#{community.identifier}/to_go")
    login_as(profile.identifier)

    post :join_not_logged, :profile => community.identifier

    assert_redirected_to "/profile/#{community.identifier}/to_go"

    assert_nil @request.session[:previous_location]
  end

  should 'show number of published events in index' do
    profile.articles << Event.new(:name => 'Published event', :start_date => Date.today)
    profile.articles << Event.new(:name => 'Unpublished event', :start_date => Date.today, :published => false)

    get :index, :profile => profile.identifier
    assert_tag :tag => 'a', :content => '1', :attributes => { :href => "/profile/testuser/events" }
  end

  should 'show number of published posts in index' do
    profile.articles << blog = Blog.create(:name => 'Blog', :profile_id => profile.id)
    fast_create(TextileArticle, :name => 'Published post', :parent_id => profile.blog.id, :profile_id => profile.id)
    fast_create(TextileArticle, :name => 'Other published post', :parent_id => profile.blog.id, :profile_id => profile.id)
    fast_create(TextileArticle, :name => 'Unpublished post', :parent_id => profile.blog.id, :profile_id => profile.id, :published => false)

    get :index, :profile => profile.identifier
    assert_tag :tag => 'a', :content => '2 posts', :attributes => { :href => /\/testuser\/blog/ }
  end

  should 'show number of published images in index' do
    folder = Gallery.create!(:name => 'gallery', :profile => profile)
    published_file = UploadedFile.create!(:profile => profile, :parent => folder, :uploaded_data => fixture_file_upload('/files/rails.png', 'image/png'))
    unpublished_file = UploadedFile.create!(:profile => profile, :parent => folder, :uploaded_data => fixture_file_upload('/files/other-pic.jpg', 'image/jpg'), :published => false)

    get :index, :profile => profile.identifier
    assert_tag :tag => 'a', :content => 'One picture', :attributes => { :href => /\/testuser\/gallery/ }
  end

  should 'show description of orgarnization' do
    login_as(@profile.identifier)
    ent = fast_create(Enterprise)
    ent.description = 'Enterprise\'s description'
    ent.save
    get :index, :profile => ent.identifier
    assert_tag :tag => 'div', :attributes => { :class => 'public-profile-description' }, :content => /Enterprise\'s description/
  end

  should 'show description of person' do
    login_as(@profile.identifier)
    @profile.description = 'Person\'s description'
    @profile.save
    get :index, :profile => @profile.identifier
    assert_tag :tag => 'div', :attributes => { :class => 'public-profile-description' }, :content => /Person\'s description/
  end

  should 'not show description of orgarnization if not filled' do
    login_as(@profile.identifier)
    ent = fast_create(Enterprise)
    get :index, :profile => ent.identifier
    assert_no_tag :tag => 'div', :attributes => { :class => 'public-profile-description' }
  end

  should 'not show description of person if not filled' do
    login_as(@profile.identifier)
    get :index, :profile => @profile.identifier
    assert_no_tag :tag => 'div', :attributes => { :class => 'public-profile-description' }
  end

  should 'ask for login if user not logged' do
    enterprise = fast_create(Enterprise)
    get :unblock, :profile => enterprise.identifier
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should ' not allow ordinary users to unblock enterprises' do
    login_as(profile.identifier)
    enterprise = fast_create(Enterprise)
    get :unblock, :profile => enterprise.identifier
    assert_response 403
  end

  should 'allow environment admin to unblock enteprises' do
    login_as(profile.identifier)
    enterprise = fast_create(Enterprise)
    enterprise.environment.add_admin(profile)
    get :unblock, :profile => enterprise.identifier
    assert_response 302
  end

  should 'escape xss attack in tag feed' do
    get :content_tagged, :profile => profile.identifier, :id => "<wslite>"
    assert_no_tag :tag => 'wslite'
  end

  should 'reverse the order of posts in tag feed' do
    TextileArticle.create!(:name => 'First post', :profile => profile, :tag_list => 'tag1', :published_at => Time.now)
    TextileArticle.create!(:name => 'Second post', :profile => profile, :tag_list => 'tag1', :published_at => Time.now + 1.day)

    get :tag_feed, :profile => profile.identifier, :id => 'tag1'
    assert_match(/Second.*First/, @response.body)
  end

  should 'display the most recent posts in tag feed' do
    start = Time.now - 30.days
    first = TextileArticle.create!(:name => 'First post', :profile => profile, :tag_list => 'tag1', :published_at => start)
    20.times do |i|
      TextileArticle.create!(:name => 'Post #' + i.to_s, :profile => profile, :tag_list => 'tag1', :published_at => start + i.days)
    end
    last = TextileArticle.create!(:name => 'Last post', :profile => profile, :tag_list => 'tag1', :published_at => Time.now)

    get :tag_feed, :profile => profile.identifier, :id => 'tag1'
    assert_no_match(/First post/, @response.body) # First post is older than other 20 posts already
    assert_match(/Last post/, @response.body) # Latest post must come in the feed
  end

  should "be logged in to leave a scrap" do
    count = Scrap.count
    post :leave_scrap, :profile => profile.identifier, :scrap => {:content => 'something'}
    assert_equal count, Scrap.count
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should "leave a scrap in the own profile" do
    login_as(profile.identifier)
    count = Scrap.count
    assert profile.scraps_received.empty?
    post :leave_scrap, :profile => profile.identifier, :scrap => {:content => 'something'}
    assert_equal count + 1, Scrap.count
    assert_response :success
    assert_equal "Message successfully sent.", assigns(:message)
    profile.reload
    assert !profile.scraps_received.empty?
  end

  should "leave a scrap on another profile" do
    login_as(profile.identifier)
    count = Scrap.count
    another_person = fast_create(Person)
    assert another_person.scraps_received.empty?
    post :leave_scrap, :profile => another_person.identifier, :scrap => {:content => 'something'}
    assert_equal count + 1, Scrap.count
    assert_response :success
    assert_equal "Message successfully sent.", assigns(:message)
    another_person.reload
    assert !another_person.scraps_received.empty?
  end

  should "the owner of scrap could remove it" do
    login_as(profile.identifier)
    scrap = fast_create(Scrap, :sender_id => profile.id)
    count = Scrap
    assert_difference Scrap, :count, -1 do
      post :remove_scrap, :profile => profile.identifier, :scrap_id => scrap.id
    end
  end

  should "the receiver scrap remove it" do
    login_as(profile.identifier)
    scrap = fast_create(Scrap, :receiver_id => profile.id)
    count = Scrap
    assert_difference Scrap, :count, -1 do
      post :remove_scrap, :profile => profile.identifier, :scrap_id => scrap.id
    end
  end

  should "not remove others scraps" do
    login_as(profile.identifier)
    person = fast_create(Person)
    scrap = fast_create(Scrap, :sender_id => person.id, :receiver_id => person.id)
    count = Scrap
    assert_difference Scrap, :count, 0 do
      post :remove_scrap, :profile => profile.identifier, :scrap_id => scrap.id
    end
  end

  should "be logged in to remove a scrap" do
    count = Scrap.count
    post :remove_scrap, :profile => profile.identifier, :scrap => {:content => 'something'}
    assert_equal count, Scrap.count
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should "not remove an scrap of another user" do
    login_as(profile.identifier)
    p1 = fast_create(Person)
    p2 = fast_create(Person)
    scrap = fast_create(Scrap, :sender_id => p1.id, :receiver_id => p2.id)
    count = Scrap.count
    post :remove_scrap, :profile => p2.identifier, :scrap_id => scrap.id
    assert_equal count, Scrap.count
  end

  should "the sender be the logged user by default" do
    login_as(profile.identifier)
    count = Scrap.count
    another_person = fast_create(Person)
    post :leave_scrap, :profile => another_person.identifier, :scrap => {:content => 'something'}
    last = Scrap.last
    assert_equal profile, last.sender
  end

 should "the receiver be the current profile by default" do
    login_as(profile.identifier)
    count = Scrap.count
    another_person = fast_create(Person)
    post :leave_scrap, :profile => another_person.identifier, :scrap => {:content => 'something'}
    last = Scrap.last
    assert_equal another_person, last.receiver
  end

  should "report to user the scrap errors on creation" do
    login_as(profile.identifier)
    count = Scrap.count
    post :leave_scrap, :profile => profile.identifier, :scrap => {:content => ''}
    assert_response :success
    assert_equal "You can't leave an empty message.", assigns(:message)
  end

  should "display a scrap sent" do
    another_person = fast_create(Person)
    Scrap.create!(defaults_for_scrap(:sender => another_person, :receiver => profile, :content => 'A scrap'))
    login_as(profile.identifier)
    get :index, :profile => profile.identifier
    assert_tag :tag => 'p', :content => 'A scrap'
  end

  should "not display a scrap sent by a removed user" do
    another_person = fast_create(Person)
    Scrap.create!(defaults_for_scrap(:sender => another_person, :receiver => profile, :content => 'A scrap'))
    login_as(profile.identifier)
    another_person.destroy
    get :index, :profile => profile.identifier
    assert_no_tag :tag => 'p', :content => 'A scrap'
  end

  should 'not display activities of the current profile when he is not followed by the viewer' do
    p1= fast_create(Person)
    p2= fast_create(Person)

    UserStampSweeper.any_instance.stubs(:current_user).returns(p1)
    scrap1 = Scrap.create!(defaults_for_scrap(:sender => p1, :receiver => p2))

    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    scrap2 = Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => p1))

    UserStampSweeper.any_instance.stubs(:current_user).returns(p1)
    TinyMceArticle.create!(:profile => p1, :name => 'An article about free software')
    a1 = ActionTracker::Record.last

    login_as(profile.identifier)
    get :index, :profile => p1.identifier
    assert_nil assigns(:activities)
  end

  should 'see the activities_items paginated' do
    p1= Person.first
    ActionTracker::Record.destroy_all
    40.times{Scrap.create!(defaults_for_scrap(:sender => p1, :receiver => p1))}
    login_as(p1.identifier)
    get :index, :profile => p1.identifier
    assert_equal 15, assigns(:activities).count
  end

  should 'not see the friends activities in the current profile' do
    p2= fast_create(Person)
    assert !profile.is_a_friend?(p2)
    p3= fast_create(Person)
    p3.add_friend(profile)
    assert p3.is_a_friend?(profile)
    ActionTracker::Record.destroy_all

    scrap1 = Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => p3))
    scrap2 = Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => profile))

    UserStampSweeper.any_instance.stubs(:current_user).returns(p3)
    article1 = TinyMceArticle.create!(:profile => p3, :name => 'An article about free software')

    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    article2 = TinyMceArticle.create!(:profile => p2, :name => 'Another article about free software')

    login_as(profile.identifier)
    get :index, :profile => p3.identifier
    assert_not_nil assigns(:activities)
    assert_equivalent [scrap1, article1.activity], assigns(:activities).map { |a| a.klass.constantize.find(a.id) }
  end

  should 'see all the activities in the current profile network' do
    p1= Person.first
    p2= fast_create(Person)
    assert !p1.is_a_friend?(p2)
    p3= fast_create(Person)
    p3.add_friend(p1)
    assert p3.is_a_friend?(p1)
    ActionTracker::Record.destroy_all
    Scrap.create!(defaults_for_scrap(:sender => p1, :receiver => p1))
    a1 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => p3))
    a2 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p3)
    Scrap.create!(defaults_for_scrap(:sender => p3, :receiver => p1))
    a3 = ActionTracker::Record.last


    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p3)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    Person.any_instance.stubs(:follows?).returns(true)

    process_delayed_job_queue
    get :index, :profile => p1.identifier
    assert_not_nil assigns(:network_activities)
    assert_equal [], [a1,a3] - assigns(:network_activities)
    assert_equal assigns(:network_activities) - [a1, a3], []
  end

  should 'the network activity be visible only to profile followers' do
    p1= Person.first
    p2= fast_create(Person)
    assert !p1.is_a_friend?(p2)
    p3= fast_create(Person)
    p3.add_friend(p1)
    assert p3.is_a_friend?(p1)
    ActionTracker::Record.destroy_all
    Scrap.create!(defaults_for_scrap(:sender => p1, :receiver => p1))
    a1 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => p3))
    a2 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p3)
    Scrap.create!(defaults_for_scrap(:sender => p3, :receiver => p1))
    a3 = ActionTracker::Record.last

    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p2)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    get :index, :profile => p1.identifier
    assert_equal [], assigns(:network_activities)

    user = mock()
    user.stubs(:person).returns(p3)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    Person.any_instance.stubs(:follows?).returns(true)
    process_delayed_job_queue
    get :index, :profile => p3.identifier
    assert_equal [], [a1,a3] - assigns(:network_activities)
    assert_equal assigns(:network_activities) - [a1, a3], []
  end

  should 'the network activity be paginated' do
    p1= Person.first
    40.times{fast_create(ActionTrackerNotification, :action_tracker_id => fast_create(ActionTracker::Record), :profile_id => p1.id)}

    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p1)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    get :index, :profile => p1.identifier
    assert_equal 15, assigns(:network_activities).count
  end

  should 'the network activity be visible only to logged users' do
    p1= ActionTracker::Record.current_user_from_model
    p2= fast_create(Person)
    assert !p1.is_a_friend?(p2)
    p3= fast_create(Person)
    p3.add_friend(p1)
    assert p3.is_a_friend?(p1)
    ActionTracker::Record.destroy_all
    Scrap.create!(defaults_for_scrap(:sender => p1, :receiver => p1))
    a1 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => p3))
    a2 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p3)
    Scrap.create!(defaults_for_scrap(:sender => p3, :receiver => p1))
    a3 = ActionTracker::Record.last

    login_as(profile.identifier)
    ActionTracker::Record.delete_all
    get :index, :profile => p1.identifier
    assert_equal [], assigns(:network_activities)
    assert_response :success
    assert_template 'index'

    get :index, :profile => p2.identifier
    assert_equal [], assigns(:network_activities)
    assert_response :success
    assert_template 'index'

    get :index, :profile => p3.identifier
    assert_equal [], assigns(:network_activities)
    assert_response :success
    assert_template 'index'
  end

  should 'the network activity be visible to uses not logged in on communities and enteprises' do
    p1= Person.first
    community = fast_create(Community)
    p2= fast_create(Person)
    assert !p1.is_a_friend?(p2)
    community.add_member(p1)
    community.add_member(p2)
    ActionTracker::Record.destroy_all
    Article.create! :name => 'a', :profile_id => community.id
    Article.create! :name => 'b', :profile_id => community.id
    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    Article.create! :name => 'c', :profile_id => community.id
    process_delayed_job_queue

    get :index, :profile => community.identifier
    assert_not_equal [], assigns(:network_items)
    assert_response :success
    assert_template 'index'
  end

  should 'the network activity be paginated on communities' do
    community = fast_create(Community)
    40.times{ fast_create(ActionTrackerNotification, :profile_id => community.id, :action_tracker_id => fast_create(ActionTracker::Record, :user_id => profile.id)) }
    get :index, :profile => community.identifier
    assert_equal 15, assigns(:network_activities).count
  end

  should 'the self activity not crashes with user not logged in' do
    p1= Person.first
    p2= fast_create(Person)
    assert !p1.is_a_friend?(p2)
    p3= fast_create(Person)
    p3.add_friend(p1)
    assert p3.is_a_friend?(p1)
    ActionTracker::Record.destroy_all
    Scrap.create!(defaults_for_scrap(:sender => p1, :receiver => p1))
    a1 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p2)
    Scrap.create!(defaults_for_scrap(:sender => p2, :receiver => p3))
    a2 = ActionTracker::Record.last
    UserStampSweeper.any_instance.stubs(:current_user).returns(p3)
    Scrap.create!(defaults_for_scrap(:sender => p3, :receiver => p1))
    a3 = ActionTracker::Record.last

    get :index, :profile => p1.identifier
    assert_response :success
    assert_template 'index'
  end

  should 'not have activities defined if not logged in' do
    p1= fast_create(Person)
    get :index, :profile => p1.identifier
    assert_nil assigns(:actvities)
  end

  should 'not have activities defined if logged in but is not following profile' do
    login_as(profile.identifier)
    p1= fast_create(Person)
    get :index, :profile => p1.identifier
    assert_nil assigns(:activities)
  end

  should 'have activities defined if logged in and is following profile' do
    login_as(profile.identifier)
    p1= fast_create(Person)
    p1.add_friend(profile)
    ActionTracker::Record.destroy_all
    get :index, :profile => p1.identifier
    assert_equal [], assigns(:activities)
  end

  should 'the activities be the received scraps in people profile' do
    p1 = ActionTracker::Record.current_user_from_model
    p2 = fast_create(Person)
    p3 = fast_create(Person)
    s1 = fast_create(Scrap, :sender_id => p1.id, :receiver_id => p2.id)
    s2 = fast_create(Scrap, :sender_id => p2.id, :receiver_id => p1.id)
    s3 = fast_create(Scrap, :sender_id => p3.id, :receiver_id => p1.id)

    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p1)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    Person.any_instance.stubs(:follows?).returns(true)
    get :index, :profile => p1.identifier
    assert_equal [s2,s3], assigns(:activities)
  end

  should 'the activities be the received scraps in community profile' do
    c = fast_create(Community)
    p1 = fast_create(Person)
    p2 = fast_create(Person)
    p3 = fast_create(Person)
    s1 = fast_create(Scrap, :sender_id => p1.id, :receiver_id => p2.id)
    s2 = fast_create(Scrap, :sender_id => p2.id, :receiver_id => c.id)
    s3 = fast_create(Scrap, :sender_id => p3.id, :receiver_id => c.id)

    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p1)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    Person.any_instance.stubs(:follows?).returns(true)
    get :index, :profile => c.identifier
    assert_equivalent [s2,s3], assigns(:activities)
  end

  should 'the activities be paginated in people profiles' do
    p1 = Person.first
    40.times{fast_create(Scrap, :receiver_id => p1.id, :created_at => Time.now)}

    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p1)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    Person.any_instance.stubs(:follows?).returns(true)
    assert_equal 40, p1.scraps_received.not_replies.count
    get :index, :profile => p1.identifier
    assert_equal 15, assigns(:activities).count
  end

  should 'the activities be paginated in community profiles' do
    p1 = Person.first
    c = fast_create(Community)
    40.times{fast_create(Scrap, :receiver_id => c.id)}

    @controller.stubs(:logged_in?).returns(true)
    user = mock()
    user.stubs(:person).returns(p1)
    user.stubs(:login).returns('some')
    @controller.stubs(:current_user).returns(user)
    Person.any_instance.stubs(:follows?).returns(true)
    assert_equal 40, c.scraps_received.not_replies.count
    get :index, :profile => c.identifier
    assert_equal 15, assigns(:activities).count
  end

  should "the owner of activity could remove it" do
    login_as(profile.identifier)
    at = fast_create(ActionTracker::Record, :user_id => profile.id)
    assert_difference ActionTracker::Record, :count, -1 do
      post :remove_activity, :profile => profile.identifier, :activity_id => at.id
    end
  end

  should "remove the network activities dependent an ActionTracker::Record" do
    login_as(profile.identifier)
    person = fast_create(Person)
    at = fast_create(ActionTracker::Record, :user_id => profile.id)
    atn = fast_create(ActionTrackerNotification, :profile_id => person.id, :action_tracker_id => at.id)
    count = ActionTrackerNotification
    assert_difference ActionTrackerNotification, :count, -1 do
      post :remove_activity, :profile => profile.identifier, :activity_id => at.id
    end
  end

  should "be logged in to remove the activity" do
    at = fast_create(ActionTracker::Record, :user_id => profile.id)
    atn = fast_create(ActionTrackerNotification, :profile_id => profile.id, :action_tracker_id => at.id)
    count = ActionTrackerNotification.count
    post :remove_activity, :profile => profile.identifier, :activity_id => at.id
    assert_equal count, ActionTrackerNotification.count
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should "remove an activity of another person if user has permissions to edit it" do
    user = create_user('owner').person
    login_as(user.identifier)
    owner = create_user('owner').person
    activity = fast_create(ActionTracker::Record, :user_id => owner.id)
    @controller.stubs(:user).returns(user)
    @controller.stubs(:profile).returns(owner)

    assert_no_difference ActionTracker::Record, :count do
      post :remove_activity, :profile => owner.identifier, :activity_id => activity.id
    end

    owner.environment.add_admin(user)

    assert_difference ActionTracker::Record, :count, -1 do
      post :remove_activity, :profile => owner.identifier, :activity_id => activity.id
    end
  end

  should "remove a notification of another profile if user has permissions to edit it" do
    user = create_user('owner').person
    login_as(user.identifier)
    profile = fast_create(Profile)
    activity = fast_create(ActionTracker::Record, :user_id => user.id)
    fast_create(ActionTrackerNotification, :profile_id => profile.id, :action_tracker_id => activity.id)
    @controller.stubs(:user).returns(user)
    @controller.stubs(:profile).returns(profile)

    assert_no_difference ActionTrackerNotification, :count do
      post :remove_notification, :profile => profile.identifier, :activity_id => activity.id
    end

    profile.environment.add_admin(user)

    assert_difference ActionTrackerNotification, :count, -1 do
      post :remove_activity, :profile => profile.identifier, :activity_id => activity.id
    end
  end

  should "not show the network activity if the viewer don't follow the profile" do
    login_as(profile.identifier)
    person = fast_create(Person)
    at = fast_create(ActionTracker::Record, :user_id => person.id)
    atn = fast_create(ActionTrackerNotification, :profile_id => profile.id, :action_tracker_id => at.id) 
    get :index, :profile => person.identifier
    assert_no_tag :tag => 'div', :attributes => {:id => 'profile-network'}

    person.add_friend(profile)
    get :index, :profile => person.identifier
    assert_tag :tag => 'div', :attributes => {:id => 'profile-network'}
  end

  should "not show the scrap button on network activity if the user is himself" do
    login_as(profile.identifier)
    at = fast_create(ActionTracker::Record, :user_id => profile.id)
    atn = fast_create(ActionTrackerNotification, :profile_id => profile.id, :action_tracker_id => at.id) 
    get :index, :profile => profile.identifier
    assert_no_tag :tag => 'p', :attributes => {:class => 'profile-network-send-message'}
  end

  should "not show the scrap area on wall if the user don't follow the user" do
    login_as(profile.identifier)
    person = fast_create(Person)
    scrap = fast_create(Scrap, :sender_id => person.id, :receiver_id => profile.id)
    get :index, :profile => person.identifier
    assert_no_tag :tag => 'div', :attributes => {:id => 'leave_scrap'}, :descendant => { :tag => 'input', :attributes => {:value => 'Share'} }

    person.add_friend(profile)
    get :index, :profile => person.identifier
    assert_tag :tag => 'div', :attributes => {:id => 'leave_scrap'}, :descendant => { :tag => 'input', :attributes => {:value => 'Share'} }
  end

  should "not show the scrap button on wall activity if the user is himself" do
    login_as(profile.identifier)
    scrap = fast_create(Scrap, :sender_id => profile.id, :receiver_id => profile.id)
    get :index, :profile => profile.identifier
    assert_no_tag :tag => 'p', :attributes => {:class => 'profile-wall-send-message'}
  end

  should "not show the activities to offline users if the profile is private" do
    at = fast_create(ActionTracker::Record, :user_id => profile.id)
    profile.public_profile=false
    profile.save
    atn = fast_create(ActionTrackerNotification, :profile_id => profile.id, :action_tracker_id => at.id) 
    get :index, :profile => profile.identifier
    assert_equal [at], profile.tracked_actions
    assert_no_tag :tag => 'li', :attributes => {:id => "profile-activity-item-#{atn.id}"}
  end

  should "view more activities paginated" do
    login_as(profile.identifier)
    article = TinyMceArticle.create!(:profile => profile, :name => 'An Article about Free Software')
    ActionTracker::Record.destroy_all
    40.times{ ActionTracker::Record.create!(:user_id => profile.id, :user_type => 'Profile', :verb => 'create_article', :target_id => article.id, :target_type => 'Article', :params => {'name' => article.name, 'url' => article.url, 'lead' => article.lead, 'first_image' => article.first_image})}
    assert_equal 40, profile.tracked_actions.count
    assert_equal 40, profile.activities.count
    get :view_more_activities, :profile => profile.identifier, :page => 2
    assert_response :success
    assert_template '_profile_activities_list'
    assert_equal 10, assigns(:activities).count
  end

  should "be logged in to access the view_more_activities action" do
    get :view_more_activities, :profile => profile.identifier
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should "view more network activities paginated" do
    login_as(profile.identifier)
    40.times{fast_create(ActionTrackerNotification, :profile_id => profile.id, :action_tracker_id => fast_create(ActionTracker::Record, :user_id => profile.id)) }
    assert_equal 40, profile.tracked_notifications.count
    get :view_more_network_activities, :profile => profile.identifier, :page => 2
    assert_response :success
    assert_template '_profile_network_activities'
    assert_equal 10, assigns(:activities).count
  end

  should "be logged in to access the view_more_network_activities action" do
    get :view_more_network_activities, :profile => profile.identifier
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should 'render empty response for not logged in users in check_membership' do
    get :check_membership
    assert_equal '', @response.body
  end

  should 'render empty response for not logged in users in check_friendship' do
    get :check_friendship
    assert_equal '', @response.body
  end

  should 'display plugins tabs' do
    class Plugin1 < Noosfero::Plugin
      def profile_tabs
        {:title => 'Plugin1 tab', :id => 'plugin1_tab', :content => lambda { 'Content from plugin1.' }}
      end
    end

    class Plugin2 < Noosfero::Plugin
      def profile_tabs
        {:title => 'Plugin2 tab', :id => 'plugin2_tab', :content => lambda { 'Content from plugin2.' }}
      end
    end

    e = profile.environment
    e.enable_plugin(Plugin1.name)
    e.enable_plugin(Plugin2.name)

    get :index, :profile => profile.identifier

    plugin1 = Plugin1.new
    plugin2 = Plugin2.new

    assert_tag :tag => 'a', :content => /#{plugin1.profile_tabs[:title]}/, :attributes => {:href => /#{plugin1.profile_tabs[:id]}/}
    assert_tag :tag => 'div', :content => /#{instance_eval(&plugin1.profile_tabs[:content])}/, :attributes => {:id => /#{plugin1.profile_tabs[:id]}/}
    assert_tag :tag => 'a', :content => /#{plugin2.profile_tabs[:title]}/, :attributes => {:href => /#{plugin2.profile_tabs[:id]}/}
    assert_tag :tag => 'div', :content => /#{instance_eval(&plugin2.profile_tabs[:content])}/, :attributes => {:id => /#{plugin2.profile_tabs[:id]}/}
  end

  should 'redirect to profile page when try to request join_not_logged via GET method' do
    community = Community.create!(:name => 'my test community')
    login_as(profile.identifier)
    get :join_not_logged, :profile => community.identifier
    assert_nothing_raised do
      assert_redirected_to community.url
    end
  end

  should 'check different profile from the domain profile' do
    default = Environment.default
    default.domains.create!(:name => 'environment.com')
    profile = create_user('another_user').person
    domain_profile = create_user('domain_user').person
    domain_profile.domains.create!(:name => 'profiledomain.com')

    @request.expects(:host).returns('profiledomain.com').at_least_once
    get :index, :profile => profile.identifier
    assert_response :redirect
    assert_redirected_to @request.params.merge(:host => profile.default_hostname)

    @request.expects(:host).returns(profile.default_hostname).at_least_once
    get :index, :profile => profile.identifier
    assert_response :success
  end

  should 'redirect to profile domain if it has one' do
    community = fast_create(Community, :name => 'community with domain')
    community.domains << Domain.new(:name => 'community.example.net')
    @request.stubs(:host).returns(community.environment.default_hostname)
    get :index, :profile => community.identifier
    assert_response :redirect
    assert_redirected_to :host => 'community.example.net', :controller => 'profile', :action => 'index'
  end

  should 'register abuse report' do
    reported = fast_create(Profile)
    login_as(profile.identifier)
    @controller.stubs(:verify_recaptcha).returns(true)

    assert_difference AbuseReport, :count, 1 do
      post :register_report, :profile => reported.identifier, :abuse_report => {:reason => 'some reason'}
    end
  end

  should 'not ask admin for captcha to register abuse' do
    reported = fast_create(Profile)
    login_as(profile.identifier)
    environment = Environment.default
    environment.add_admin(profile)
    @controller.expects(:verify_recaptcha).never

    assert_difference AbuseReport, :count, 1 do
      post :register_report, :profile => reported.identifier, :abuse_report => {:reason => 'some reason'}
    end
  end

  should 'display activities and scraps together' do
    another_person = fast_create(Person)
    Scrap.create!(defaults_for_scrap(:sender => another_person, :receiver => profile, :content => 'A scrap'))

    UserStampSweeper.any_instance.stubs(:current_user).returns(profile)
    ActionTracker::Record.destroy_all
    TinyMceArticle.create!(:profile => profile, :name => 'An article about free software')

    login_as(profile.identifier)
    get :index, :profile => profile.identifier

    assert_tag :tag => 'p', :content => 'A scrap', :attributes => { :class => 'profile-activity-text'} 
    assert_tag :tag => 'div', :attributes => { :class => 'profile-activity-lead' }, :descendant => { :tag => 'a', :content => 'An article about free software' }
  end

  should 'have scraps and activities on activities' do
    another_person = fast_create(Person)
    scrap = Scrap.create!(defaults_for_scrap(:sender => another_person, :receiver => profile, :content => 'A scrap'))

    UserStampSweeper.any_instance.stubs(:current_user).returns(profile)
    ActionTracker::Record.destroy_all
    TinyMceArticle.create!(:profile => profile, :name => 'An article about free software')
    activity = ActionTracker::Record.last

    login_as(profile.identifier)
    get :index, :profile => profile.identifier

    assert_equivalent [scrap,activity], assigns(:activities).map {|a| a.klass.constantize.find(a.id)}
  end

  should "be logged in to leave comment on an activity" do
    article = TinyMceArticle.create!(:profile => profile, :name => 'An article about free software')
    activity = ActionTracker::Record.last
    count = activity.comments.count

    post :leave_comment_on_activity, :profile => profile.identifier, :comment => {:body => 'something', :source_id => activity.id}
    assert_equal count, activity.comments.count
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  should "leave a comment in own activity" do
    login_as(profile.identifier)
    TinyMceArticle.create!(:profile => profile, :name => 'An article about free software')
    activity = ActionTracker::Record.last
    count = activity.comments.count

    assert_equal 0, count
    post :leave_comment_on_activity, :profile => profile.identifier, :comment => {:body => 'something'}, :source_id => activity.id
    assert_equal count + 1, ActionTracker::Record.find(activity.id).comments_count
    assert_response :success
    assert_equal "Comment successfully added.", assigns(:message)
  end

  should "leave a comment on another profile's activity" do
    login_as(profile.identifier)
    another_person = fast_create(Person)
    TinyMceArticle.create!(:profile => another_person, :name => 'An article about free software')
    activity = ActionTracker::Record.last
    count = activity.comments.count
    assert_equal 0, count
    post :leave_comment_on_activity, :profile => another_person.identifier, :comment => {:body => 'something'}, :source_id => activity.id
    assert_equal count + 1, ActionTracker::Record.find(activity.id).comments_count
    assert_response :success
    assert_equal "Comment successfully added.", assigns(:message)
  end

  should 'display comment in wall if user was removed' do
    UserStampSweeper.any_instance.stubs(:current_user).returns(profile)
    article = TinyMceArticle.create!(:profile => profile, :name => 'An article about free software')
    to_be_removed = create_user('removed_user').person
    comment = Comment.create!(:author => to_be_removed, :title => 'Test Comment', :body => 'My author does not exist =(', :source_id => article.id, :source_type => 'Article')
    to_be_removed.destroy

    login_as(profile.identifier)
    get :index, :profile => profile.identifier

    assert_tag :tag => 'span', :content => '(removed user)', :attributes => {:class => 'comment-user-status comment-user-status-wall icon-user-removed'}
  end

  should 'display comment in wall from non logged users' do
    UserStampSweeper.any_instance.stubs(:current_user).returns(profile)
    article = TinyMceArticle.create!(:profile => profile, :name => 'An article about free software')
    comment = Comment.create!(:name => 'outside user', :email => 'outside@localhost.localdomain', :title => 'Test Comment', :body => 'My author does not exist =(', :source_id => article.id, :source_type => 'Article')

    login_as(profile.identifier)
    get :index, :profile => profile.identifier

    assert_tag :tag => 'span', :content => '(unauthenticated user)', :attributes => {:class => 'comment-user-status comment-user-status-wall icon-user-unknown'}
  end

  should 'add locale on mailing' do
    community = fast_create(Community)
    create_user_with_permission('profile_moderator_user', 'send_mail_to_members', community)
    login_as('profile_moderator_user')
    @controller.stubs(:locale).returns('pt')
    post :send_mail, :profile => community.identifier, :mailing => {:subject => 'Hello', :body => 'We have some news'}
    assert_equal 'pt', assigns(:mailing).locale
  end

  should 'queue mailing to process later' do
    community = fast_create(Community)
    create_user_with_permission('profile_moderator_user', 'send_mail_to_members', community)
    login_as('profile_moderator_user')
    @controller.stubs(:locale).returns('pt')
    assert_difference Delayed::Job, :count, 1 do
      post :send_mail, :profile => community.identifier, :mailing => {:subject => 'Hello', :body => 'We have some news'}
    end
  end

  should 'save mailing' do
    community = fast_create(Community)
    create_user_with_permission('profile_moderator_user', 'send_mail_to_members', community)
    login_as('profile_moderator_user')
    @controller.stubs(:locale).returns('pt')
    post :send_mail, :profile => community.identifier, :mailing => {:subject => 'Hello', :body => 'We have some news'}
    assert_equal ['Hello', 'We have some news'], [assigns(:mailing).subject, assigns(:mailing).body]
  end

  should 'add the user logged on mailing' do
    community = fast_create(Community)
    create_user_with_permission('profile_moderator_user', 'send_mail_to_members', community)
    login_as('profile_moderator_user')
    post :send_mail, :profile => community.identifier, :mailing => {:subject => 'Hello', :body => 'We have some news'}
    assert_equal Profile['profile_moderator_user'], assigns(:mailing).person
  end

  should 'redirect back to right place after mail' do
    community = fast_create(Community)
    create_user_with_permission('profile_moderator_user', 'send_mail_to_members', community)
    login_as('profile_moderator_user')
    @controller.stubs(:locale).returns('pt')
    @request.expects(:referer).returns("/profile/#{community.identifier}/members")
    post :send_mail, :profile => community.identifier, :mailing => {:subject => 'Hello', :body => 'We have some news'}
    assert_redirected_to :action => 'members'
  end

  should 'show all fields to anonymous user' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:active_person_fields).returns(['sex', 'birth_date'])
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.birth_date = Time.parse('2012-08-26').ago(22.years)
    viewed.data = { :sex => 'male', :fields_privacy => { 'sex' => 'public', 'birth_date' => 'public' } }
    viewed.save!
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'td', :content => 'Sex:'
    assert_tag :tag => 'td', :content => 'Male'
    assert_tag :tag => 'td', :content => 'Date of birth:'
    assert_tag :tag => 'td', :content => 'August 26, 1990'
  end

  should 'show some fields to anonymous user' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:active_person_fields).returns(['sex', 'birth_date'])
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.birth_date = Time.parse('2012-08-26').ago(22.years)
    viewed.data = { :sex => 'male', :fields_privacy => { 'sex' => 'public' } }
    viewed.save!
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'td', :content => 'Sex:'
    assert_tag :tag => 'td', :content => 'Male'
    assert_no_tag :tag => 'td', :content => 'Date of birth:'
    assert_no_tag :tag => 'td', :content => 'August 26, 1990'
  end

  should 'show some fields to non friend' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:active_person_fields).returns(['sex', 'birth_date'])
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.birth_date = Time.parse('2012-08-26').ago(22.years)
    viewed.data = { :sex => 'male', :fields_privacy => { 'sex' => 'public' } }
    viewed.save!
    strange = create_user('person_2').person
    login_as(strange.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'td', :content => 'Sex:'
    assert_tag :tag => 'td', :content => 'Male'
    assert_no_tag :tag => 'td', :content => 'Date of birth:'
    assert_no_tag :tag => 'td', :content => 'August 26, 1990'
  end

  should 'show all fields to friend' do
    viewed = create_user('person_1').person
    friend = create_user('person_2').person
    Environment.any_instance.stubs(:active_person_fields).returns(['sex', 'birth_date'])
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.birth_date = Time.parse('2012-08-26').ago(22.years)
    viewed.data = { :sex => 'male', :fields_privacy => { 'sex' => 'public' } }
    viewed.save!
    Person.any_instance.stubs(:is_a_friend?).returns(true)
    login_as(friend.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'td', :content => 'Sex:'
    assert_tag :tag => 'td', :content => 'Male'
    assert_tag :tag => 'td', :content => 'Date of birth:'
    assert_tag :tag => 'td', :content => 'August 26, 1990'
  end

  should 'show all fields to self' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:active_person_fields).returns(['sex', 'birth_date'])
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.birth_date = Time.parse('2012-08-26').ago(22.years)
    viewed.data = { :sex => 'male', :fields_privacy => { 'sex' => 'public' } }
    viewed.save!
    login_as(viewed.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'td', :content => 'Sex:'
    assert_tag :tag => 'td', :content => 'Male'
    assert_tag :tag => 'td', :content => 'Date of birth:'
    assert_tag :tag => 'td', :content => 'August 26, 1990'
  end

  should 'show contact to non friend' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.data = { :email => 'test@test.com', :fields_privacy => { 'email' => 'public' } }
    viewed.save!
    strange = create_user('person_2').person
    login_as(strange.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'th', :content => 'Contact'
    assert_tag :tag => 'td', :content => 'e-Mail:'
  end

  should 'show contact to friend' do
    viewed = create_user('person_1').person
    friend = create_user('person_2').person
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.data = { :email => 'test@test.com', :fields_privacy => { 'email' => 'public' } }
    viewed.save!
    Person.any_instance.stubs(:is_a_friend?).returns(true)
    login_as(friend.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'th', :content => 'Contact'
    assert_tag :tag => 'td', :content => 'e-Mail:'
  end

  should 'show contact to self' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.data = { :email => 'test@test.com', :fields_privacy => { 'email' => 'public' } }
    viewed.save!
    login_as(viewed.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'th', :content => 'Contact'
    assert_tag :tag => 'td', :content => 'e-Mail:'
  end

  should 'not show contact to non friend' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.data = { :email => 'test@test.com', :fields_privacy => { } }
    viewed.save!
    strange = create_user('person_2').person
    login_as(strange.identifier)
    get :index, :profile => viewed.identifier
    assert_no_tag :tag => 'th', :content => 'Contact'
    assert_no_tag :tag => 'td', :content => 'e-Mail:'
  end

  should 'show contact to friend even if private' do
    viewed = create_user('person_1').person
    friend = create_user('person_2').person
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.data = { :email => 'test@test.com', :fields_privacy => { } }
    viewed.save!
    Person.any_instance.stubs(:is_a_friend?).returns(true)
    login_as(friend.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'th', :content => 'Contact'
    assert_tag :tag => 'td', :content => 'e-Mail:'
  end

  should 'show contact to self even if private' do
    viewed = create_user('person_1').person
    Environment.any_instance.stubs(:required_person_fields).returns([])
    viewed.data = { :email => 'test@test.com', :fields_privacy => { } }
    viewed.save!
    login_as(viewed.identifier)
    get :index, :profile => viewed.identifier
    assert_tag :tag => 'th', :content => 'Contact'
    assert_tag :tag => 'td', :content => 'e-Mail:'
  end

  should 'show enterprises field if enterprises are enabled on environment' do
    person = fast_create(Person)
    environment = person.environment
    environment.disable('disable_asset_enterprises')
    environment.save!

    get :index, :profile => person.identifier
    assert_tag :tag => 'tr', :attributes => { :id => "person-profile-network-enterprises" }
  end

  should 'not show enterprises field if enterprises are disabled on environment' do
    person = fast_create(Person)
    environment = person.environment
    environment.enable('disable_asset_enterprises')
    environment.save!

    get :index, :profile => person.identifier
    assert_no_tag :tag => 'tr', :attributes => { :id => "person-profile-network-enterprises" }
  end

end
