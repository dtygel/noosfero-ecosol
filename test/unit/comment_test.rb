require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase

  def setup
  end

  should 'have a name but not require it' do
    assert_optional(Comment.new, :title)
  end

  should 'have a body and require it' do
    assert_mandatory(Comment.new, :body)
  end

  should 'have a polymorphic relationship with source' do
    c = Comment.new
    assert_nothing_raised do
      c.source = Article.new
    end
    assert_nothing_raised do
      c.source = ActionTracker::Record.new
    end
  end

  should 'record authenticated author' do
    c = Comment.new
    assert_raise ActiveRecord::AssociationTypeMismatch do
      c.author = 1
    end
    assert_raise ActiveRecord::AssociationTypeMismatch do
      c.author = Profile
    end
    assert_nothing_raised do
      c.author = Person.new
    end
  end

  should 'record unauthenticated author' do

    assert_optional Comment.new, :name
    assert_optional Comment.new, :email

    # if given name, require email
    c1 = Comment.new
    c1.name = 'My Name'
    assert_mandatory c1, :email, 'my@email.com'

    # if given email, require name
    c2 = Comment.new
    c2.email = 'my@email.com'
    assert_mandatory c2, :name
  end

  should 'accept either an authenticated or unauthenticated author' do
    assert_mandatory Comment.new, :author_id

    c1 = Comment.new
    c1.author = create_user('someperson').person
    c1.name = 'my name'
    c1.valid?
    assert c1.errors.invalid?(:name)
    assert_no_match /\{fn\}/, c1.errors.on(:name)
  end

  should 'update counter cache in article' do
    owner = create_user('testuser').person
    art = create(TextileArticle, :profile_id => owner.id)
    cc = art.comments_count

    comment = create(Comment, :source => art, :author_id => owner.id)
    assert_equal cc + 1, Article.find(art.id).comments_count
  end

  should 'update counter cache in article activity' do
    owner = create_user('testuser').person
    article = create(TextileArticle, :profile_id => owner.id)

    action = article.activity
    cc = action.comments_count
    comment = create(Comment, :source => action, :author_id => owner.id)
    assert_equal cc + 1, ActionTracker::Record.find(action.id).comments_count
  end

  should 'update counter cache in general activity when add a comment' do
    person = fast_create(Person)
    community = fast_create(Community)

    activity = ActionTracker::Record.create :user => person, :target => community, :verb => 'add_member_in_community'

    cc = activity.comments_count

    comment = create(Comment, :source => activity, :author_id => person.id)
    assert_equal cc + 1, ActionTracker::Record.find(activity.id).comments_count
  end

  should 'provide author name for authenticated authors' do
    owner = create_user('testuser').person
    assert_equal 'testuser', Comment.new(:author => owner).author_name
  end

  should 'provide author name for unauthenticated author' do
    assert_equal 'anonymous coward', Comment.new(:name => 'anonymous coward').author_name
  end

  should 'provide empty text for author name if user was removed ' do
    assert_equal '', Comment.new(:author_id => 9999).author_name
  end

  should "provide author e-mail for athenticated authors" do
    owner = create_user('testuser').person
    assert_equal owner.email, Comment.new(:author => owner).author_email
  end

  should "provide author e-mail for unauthenticated author" do
    assert_equal 'my@email.com', Comment.new(:email => 'my@email.com').author_email
  end

  should 'provide author link for authenticated author' do
    author = Person.new
    author.expects(:url).returns('http://blabla.net/author')
    assert_equal  'http://blabla.net/author', Comment.new(:author => author).author_link
  end

  should 'provide author e-mail as author link for unauthenticated author' do
    assert_equal 'my@email.com', Comment.new(:email => 'my@email.com').author_link
  end

  should 'provide url to comment' do
    art = Article.new
    art.expects(:url).returns({ :controller => 'lala', :action => 'something' })
    comment = Comment.new(:article => art)
    comment.expects(:id).returns(9876)

    assert_equal({ :controller => 'lala', :action => 'something', :anchor => 'comment-9876'}, comment.url)
  end

  should 'provide anchor' do
    comment = Comment.new
    comment.expects(:id).returns(4321)
    assert_equal 'comment-4321', comment.anchor
  end

  should 'be able to find recent comments' do
    Comment.delete_all

    owner = create_user('testuser').person
    art = owner.articles.build(:name => 'ytest'); art.save!
    comments = []
    3.times do
      comments.unshift art.comments.create!(:title => 'a test comment', :body => 'bla', :author => owner)
    end

    assert_equal comments, Comment.recent
  end

  should 'be able to find recent comments with limit' do
    Comment.delete_all

    owner = create_user('testuser').person
    art = owner.articles.build(:name => 'ytest'); art.save!
    comments = []
    3.times do
      comments.unshift art.comments.create!(:title => 'a test comment', :body => 'bla', :author => owner)
    end

    comments.pop

    assert_equal comments, Comment.recent(2)
  end

  should 'not accept invalid email' do
    c = Comment.new(:name => 'My Name', :email => 'my@invalid')
    c.valid?
    assert c.errors.invalid?(:email)
  end

  should 'generate links to comments on images with view set to true' do
    owner = create_user('testuser').person
    image = UploadedFile.create!(:profile => owner, :uploaded_data => fixture_file_upload('/files/rails.png', 'image/png'))
    comment = image.comments.create!(:article => image, :author => owner, :title => 'a random comment', :body => 'just another comment')

    assert comment.url[:view]
  end

  should 'not fill fields with javascript' do
    owner = create_user('testuser').person
    article = owner.articles.create!(:name => 'test', :body => '...')
    javascript = "<script>alert('XSS')</script>"
    comment = article.comments.create!(:article => article, :name => javascript, :title => javascript, :body => javascript, :email => 'cracker@test.org')
    assert_no_match(/<script>/, comment.name)
  end

  should 'sanitize required fields before validation' do
    owner = create_user('testuser').person
    article = owner.articles.create(:name => 'test', :body => '...')
    comment = article.comments.new(:title => '<h1 title </h1>', :body => '<h1 body </h1>', :name => '<h1 name </h1>', :email => 'cracker@test.org')
    comment.valid?

    assert comment.errors.invalid?(:name)
    assert comment.errors.invalid?(:body)
  end

  should 'escape malformed html tags' do
    owner = create_user('testuser').person
    article = owner.articles.create(:name => 'test', :body => '...')
    comment = article.comments.new(:title => '<h1 title </h1>>> sd f <<', :body => '<h1>> sdf><asd>< body </h1>', :name => '<h1 name </h1>>><<dfsf<sd', :email => 'cracker@test.org')
    comment.valid?

    assert_no_match /[<>]/, comment.title
    assert_no_match /[<>]/, comment.body
    assert_no_match /[<>]/, comment.name
  end

  should 'use an existing image for deleted comments' do
    image = Comment.new.removed_user_image
    assert File.exists?(File.join(Rails.root, 'public', image)), "#{image} does not exist."
  end

  should 'have the action_tracker_target defined' do
    assert Comment.method_defined?(:action_tracker_target)
  end

  should "get children of a comment" do
    c = fast_create(Comment)
    c1 = fast_create(Comment, :reply_of_id => c.id)
    c2 = fast_create(Comment)
    c3 = fast_create(Comment, :reply_of_id => c.id)
    assert_equal [c1,c3], c.children
  end

  should "get parent of a comment" do
    c = fast_create(Comment)
    c1 = fast_create(Comment, :reply_of_id => c.id)
    c2 = fast_create(Comment, :reply_of_id => c1.id)
    c3 = fast_create(Comment, :reply_of_id => c.id)
    c4 = fast_create(Comment)
    assert_equal c, c1.reply_of
    assert_equal c, c3.reply_of
    assert_equal c1, c2.reply_of
    assert_nil c4.reply_of
  end

  should 'destroy replies when comment is removed' do
    Comment.delete_all
    owner = create_user('testuser').person
    article = owner.articles.create!(:name => 'test', :body => '...')
    c = article.comments.create!(:article => article, :name => 'foo', :title => 'bar', :body => 'my comment', :email => 'cracker@test.org')
    c1 = article.comments.create!(:article => article, :name => 'foo', :title => 'bar', :body => 'my comment', :email => 'cracker@test.org', :reply_of_id => c.id)
    c2 = article.comments.create!(:article => article, :name => 'foo', :title => 'bar', :body => 'my comment', :email => 'cracker@test.org')
    c3 = article.comments.create!(:article => article, :name => 'foo', :title => 'bar', :body => 'my comment', :email => 'cracker@test.org', :reply_of_id => c.id)
    assert_equal 4, Comment.count
    c.destroy
    assert_equal [c2], Comment.all
  end

  should "get children if replies are not loaded" do
    c = fast_create(Comment)
    c1 = fast_create(Comment, :reply_of_id => c.id)
    c2 = fast_create(Comment)
    c3 = fast_create(Comment, :reply_of_id => c.id)
    assert_nil c.instance_variable_get('@replies')
    assert_equal [c1,c3], c.replies
  end

  should "get replies if they are loaded" do
    c = fast_create(Comment)
    c1 = fast_create(Comment, :reply_of_id => c.id)
    c2 = fast_create(Comment)
    c3 = fast_create(Comment, :reply_of_id => c.id)
    c.replies = [c2]
    assert_not_nil c.instance_variable_get('@replies')
    assert_equal [c2], c.replies
  end

  should "set replies" do
    c = fast_create(Comment)
    c1 = fast_create(Comment, :reply_of_id => c.id)
    c2 = fast_create(Comment)
    c3 = fast_create(Comment, :reply_of_id => c.id)
    c.replies = []
    c.replies << c2
    assert_equal [c2], c.instance_variable_get('@replies')
    assert_equal [c2], c.replies
    assert_equal [c1,c3], c.reload.children
  end

  should "return activities comments as a thread" do
    person = fast_create(Person)
    a = TextileArticle.create!(:profile => person, :name => 'My article', :body => 'Article body')
    c0 = Comment.create!(:source => a, :body => 'My comment', :author => person)
    c1 = Comment.create!(:reply_of_id => c0.id, :source => a, :body => 'bla', :author => person)
    c2 = Comment.create!(:reply_of_id => c1.id, :source => a, :body => 'bla', :author => person)
    c3 = Comment.create!(:reply_of_id => c0.id, :source => a, :body => 'bla', :author => person)
    c4 = Comment.create!(:source => a, :body => 'My comment', :author => person)
    result = a.activity.comments_as_thread
    assert_equal c0, result[0]
    assert_equal [c1, c3], result[0].replies
    assert_equal [c2], result[0].replies[0].replies
    assert_equal c4, result[1]
    assert result[1].replies.empty?
  end

  should "return activities comments when some comment on thread is spam" do
    person = fast_create(Person)
    a = TextileArticle.create!(:profile => person, :name => 'My article', :body => 'Article body')
    c0 = Comment.create(:source => a, :body => 'Root comment', :author => person)
    c1 = Comment.create(:reply_of_id => c0.id, :source => a, :body => 'c1', :author => person)
    spam = Comment.create(:spam => true, :reply_of_id => c0.id, :source => a, :body => 'spam', :author => person)
    c2 = Comment.create(:reply_of_id => spam.id, :source => a, :body => 'c2', :author => person)
    result = a.activity.comments_as_thread
    assert_equal c0, result[0]
    assert_equal [c1], result[0].replies
    assert_equal c2, result[1]
  end

  should 'provide author url for authenticated user' do
    author = Person.new
    author.expects(:url).returns('http://blabla.net/author')
    assert_equal  'http://blabla.net/author', Comment.new(:author => author).author_url
  end

  should 'not provide author url for unauthenticated user' do
    assert_nil Comment.new(:email => 'my@email.com').author_url
  end

  should 'be able to reject a comment' do
    c = Comment.new
    assert !c.rejected?

    c.reject!
    assert c.rejected?
  end

  should 'subscribe user as follower of an article on new comment' do
    owner = create_user('owner_of_article').person
    person = create_user('follower').person
    article = fast_create(Article, :profile_id => owner.id)
    assert_not_includes article.followers, person.email
    article.comments.create!(:source => article, :author => person, :title => 'new comment', :body => 'new comment')
    assert_includes article.reload.followers, person.email
  end

  should 'subscribe guest user as follower of an article on new comment' do
    article = fast_create(Article, :profile_id => create_user('article_owner').person.id)
    assert_not_includes article.followers, 'follower@example.com'
    article.comments.create!(:source => article, :name => 'follower', :email => 'follower@example.com', :title => 'new comment', :body => 'new comment')
    assert_includes article.reload.followers, 'follower@example.com'
  end

  should 'keep unique emails in list of followers' do
    article = fast_create(Article, :profile_id => create_user('article_owner').person.id)
    article.comments.create!(:source => article, :name => 'follower one', :email => 'follower@example.com', :title => 'new comment', :body => 'new comment')
    article.comments.create!(:source => article, :name => 'follower two', :email => 'follower@example.com', :title => 'another comment', :body => 'new comment')
    assert_equal 1, article.reload.followers.select{|v| v == 'follower@example.com'}.count
  end

  should 'not subscribe owner as follower of an article on new comment' do
    owner = create_user('owner_of_article').person
    article = fast_create(Article, :profile_id => owner.id)
    article.comments.create!(:source => article, :author => owner, :title => 'new comment', :body => 'new comment')
    assert_not_includes article.reload.followers, owner.email
  end

  should 'not subscribe admins as follower of an article on new comment' do
    owner = fast_create(Community)
    follower = create_user('follower').person
    admin = create_user('admin_of_community').person
    owner.add_admin(admin)
    article = fast_create(Article, :profile_id => owner.id)
    article.comments.create!(:source => article, :author => follower, :title => 'new comment', :body => 'new comment')
    article.comments.create!(:source => article, :author => admin, :title => 'new comment', :body => 'new comment')
    assert_not_includes article.reload.followers, admin.email
    assert_includes article.followers, follower.email
  end

  should 'update article activity when add a comment' do
    now = Time.now
    Time.stubs(:now).returns(now)

    profile = create_user('testuser').person
    article = create(TinyMceArticle, :profile => profile)

    ActionTracker::Record.record_timestamps = false
    article.activity.update_attribute(:updated_at, Time.now - 1.day)
    ActionTracker::Record.record_timestamps = true

    time = article.activity.updated_at

    comment = create(Comment, :source => article, :author => profile)
    assert_equal time + 1.day, article.activity.updated_at
  end

  should 'create a new activity when add a comment and the activity was removed' do
    profile = create_user('testuser').person
    article = create(TinyMceArticle, :profile => profile)
    article.activity.destroy

    assert_nil article.activity

    comment = create(Comment, :source => article, :author => profile)
    assert_not_nil article.activity
  end

  should 'be able to mark comments as spam/ham/unknown' do
    c = Comment.new
    c.spam = true
    assert c.spam?
    assert !c.ham?

    c.spam = false
    assert c.ham?
    assert !c.spam?

    c.spam = nil
    assert !c.spam?
    assert !c.ham?
  end

  should 'be able to select non-spam comments' do
    c1 = fast_create(Comment)
    c2 = fast_create(Comment, :spam => false)
    c3 = fast_create(Comment, :spam => true)

    assert_equivalent [c1,c2], Comment.without_spam
  end

  should 'be able to mark as spam atomically' do
    c1 = create_comment
    c1.spam!
    c1.reload
    assert c1.spam?
  end

  should 'be able to select spammy comments' do
    c1 = fast_create(Comment)
    c2 = fast_create(Comment, :spam => false)
    c3 = fast_create(Comment, :spam => true)

    assert_equivalent [c3], Comment.spam
  end

  should 'be able to mark as ham atomically' do
    c1 = create_comment
    c1.ham!
    c1.reload
    assert c1.ham?
  end

  should 'notify by email' do
    c1 = create_comment
    c1.expects(:notify_by_mail)
    c1.verify_and_notify
  end

  should 'not notify by email when comment is spam' do
    c1 = create_comment(:spam => true)
    c1.expects(:notify_by_mail).never
    c1.verify_and_notify
  end

  class EverythingIsSpam < Noosfero::Plugin
    def check_for_spam(comment)
      comment.spam!
    end
  end


  should 'delegate spam detection to plugins' do
    Environment.default.enable_plugin(EverythingIsSpam)

    c1 = create_comment

    c1.expects(:notify_by_mail).never

    c1.verify_and_notify
  end

  class SpamNotification < Noosfero::Plugin
    class << self
      attr_accessor :marked_as_spam
      attr_accessor :marked_as_ham
    end

    def marked_as_spam(c)
      self.class.marked_as_spam = c
    end

    def marked_as_ham(c)
      self.class.marked_as_ham = c
    end
  end

  should 'notify plugins of comments being marked as spam' do
    Environment.default.enable_plugin(SpamNotification)

    c = create_comment

    c.spam!
    process_delayed_job_queue

    assert_equal c, SpamNotification.marked_as_spam
  end

  should 'notify plugins of comments being marked as ham' do
    Environment.default.enable_plugin(SpamNotification)

    c = create_comment

    c.ham!
    process_delayed_job_queue

    assert_equal c, SpamNotification.marked_as_ham
  end

  should 'store User-Agent' do
    c = Comment.new(:user_agent => 'foo')
    assert_equal 'foo', c.user_agent
  end

  should 'store referrer' do
    c = Comment.new(:referrer => 'bar')
    assert_equal 'bar', c.referrer
  end

  should 'delegate environment to article' do
    profile = fast_create(Profile, :environment_id => Environment.default)
    article = fast_create(Article, :profile_id => profile.id)
    comment = fast_create(Comment, :source_id => article.id, :source_type => 'Article')

    assert_equal Environment.default, comment.environment
  end

  should 'log spammer ip after marking comment as spam' do
    comment = create_comment(:ip_address => '192.168.0.1')
    comment.spam!
    log = File.open('log/test_spammers.log')
    assert_match "Comment-id: #{comment.id} IP: 192.168.0.1", log.read
  end

  should 'not need moderation if article is not moderated' do
    article = Article.new
    comment = Comment.new(:article => article)

    assert !comment.need_moderation?
  end

  should 'not need moderation if the comment author is the article author' do
    author = Person.new
    article = Article.new

    article.stubs(:author).returns(author)
    article.moderate_comments = true

    comment = Comment.new(:article => article)
    comment.stubs(:author).returns(author)

    assert !comment.need_moderation?
  end

  should 'need moderation if article is moderated and the comment has no author' do
    article = Article.new
    article.stubs(:moderate_comments?).returns(true)

    comment = Comment.new(:article => article)

    assert comment.need_moderation?
  end

  should 'need moderation if article is moderated and the comment author is different from article author' do
    article_author = Person.new
    comment_author = Person.new

    article = Article.new
    article.stubs(:author).returns(article_author)
    article.stubs(:moderate_comments?).returns(true)

    comment = Comment.new(:article => article)
    comment.stubs(:author).returns(comment_author)

    assert comment.need_moderation?
  end

  should 'not be able to destroy comment without user' do
    comment = Comment.new

    assert !comment.can_be_destroyed_by?(nil)
  end

  should 'not be able to destroy comment' do
    user = Person.new
    profile = Profile.new
    article = Article.new(:profile => profile)
    comment = Comment.new(:article => article)
    user.expects(:has_permission?).with(:moderate_comments, profile).returns(false)

    assert !comment.can_be_destroyed_by?(user)
  end

  should 'be able to destroy comment if is the author' do
    user = Person.new
    comment = Comment.new(:author => user)

    assert comment.can_be_destroyed_by?(user)
  end

  should 'be able to destroy comment if is the profile' do
    user = Person.new
    article = Article.new(:profile => user)
    comment = Comment.new(:article => article)

    assert comment.can_be_destroyed_by?(user)
  end

  should 'be able to destroy comment if can moderate_comments on the profile' do
    user = Person.new
    profile = Profile.new
    article = Article.new(:profile => profile)
    comment = Comment.new(:article => article)

    user.expects(:has_permission?).with(:moderate_comments, profile).returns(true)

    assert comment.can_be_destroyed_by?(user)
  end

  should 'not be able to mark comment as spam without user' do
    comment = Comment.new

    assert !comment.can_be_marked_as_spam_by?(nil)
  end

  should 'not be able to mark comment as spam' do
    user = Person.new
    profile = Profile.new
    article = Article.new(:profile => profile)
    comment = Comment.new(:article => article)
    user.expects(:has_permission?).with(:moderate_comments, profile).returns(false)

    assert !comment.can_be_marked_as_spam_by?(user)
  end

  should 'be able to mark comment as spam if is the profile' do
    user = Person.new
    article = Article.new(:profile => user)
    comment = Comment.new(:article => article)

    assert comment.can_be_marked_as_spam_by?(user)
  end

  should 'be able to mark comment as spam if can moderate_comments on the profile' do
    user = Person.new
    profile = Profile.new
    article = Article.new(:profile => profile)
    comment = Comment.new(:article => article)

    user.expects(:has_permission?).with(:moderate_comments, profile).returns(true)

    assert comment.can_be_marked_as_spam_by?(user)
  end

  should 'not be able to update comment without user' do
    comment = Comment.new

    assert !comment.can_be_updated_by?(nil)
  end

  should 'not be able to update comment' do
    user = Person.new
    comment = Comment.new

    assert !comment.can_be_updated_by?(user)
  end

  should 'be able to update comment if is the author' do
    user = Person.new
    comment = Comment.new(:author => user)

    assert comment.can_be_updated_by?(user)
  end

  should 'get comment root' do
    c1 = Comment.new
    c2 = Comment.new(:reply_of => c1)
    c3 = Comment.new(:reply_of => c2)

    assert_equal c1, c3.comment_root
    assert_equal c1, c2.comment_root
    assert_equal c1, c1.comment_root
  end

  should 'be able to select non-reply comments' do
    c1 = fast_create(Comment)
    c2 = fast_create(Comment, :reply_of_id => c1.id)
    c3 = fast_create(Comment, :reply_of_id => c2.id)
    c4 = fast_create(Comment)

    assert_equivalent [c1,c4], Comment.without_reply
  end

  private

  def create_comment(args = {})
    owner = create_user('testuser').person
    article = create(TextileArticle, :profile_id => owner.id)
    create(Comment, { :name => 'foo', :email => 'foo@example.com', :source => article }.merge(args))
  end

end
