class Comment < ActiveRecord::Base

  SEARCHABLE_FIELDS = {
    :title => 10,
    :name => 4,
    :body => 2,
  }

  validates_presence_of :body

  belongs_to :source, :counter_cache => true, :polymorphic => true
  alias :article :source
  alias :article= :source=

  belongs_to :author, :class_name => 'Person', :foreign_key => 'author_id'
  has_many :children, :class_name => 'Comment', :foreign_key => 'reply_of_id', :dependent => :destroy
  belongs_to :reply_of, :class_name => 'Comment', :foreign_key => 'reply_of_id'

  named_scope :without_reply, :conditions => ['reply_of_id IS NULL']

  # unauthenticated authors:
  validates_presence_of :name, :if => (lambda { |record| !record.email.blank? })
  validates_presence_of :email, :if => (lambda { |record| !record.name.blank? })
  validates_format_of :email, :with => Noosfero::Constants::EMAIL_FORMAT, :if => (lambda { |record| !record.email.blank? })

  # require either a recognized author or an external person
  validates_presence_of :author_id, :if => (lambda { |rec| rec.name.blank? && rec.email.blank? })
  validates_each :name do |rec,attribute,value|
    if rec.author_id && (!rec.name.blank? || !rec.email.blank?)
      rec.errors.add(:name, _('{fn} can only be informed for unauthenticated authors').fix_i18n)
    end
  end

  xss_terminate :only => [ :body, :title, :name ], :on => 'validation'

  def comment_root
    (reply_of && reply_of.comment_root) || self
  end

  def action_tracker_target
    self.article.profile
  end

  def author_name
    if author
      author.short_name
    else
      author_id ? '' : name
    end
  end

  def author_email
    author ? author.email : email
  end

  def author_link
    author ? author.url : email
  end

  def author_url
    author ? author.url : nil
  end

  def url
    article.view_url.merge(:anchor => anchor)
  end

  def message
    author_id ? _('(removed user)') : _('(unauthenticated user)')
  end

  def removed_user_image
    '/images/icons-app/person-minor.png'
  end

  def anchor
    "comment-#{id}"
  end

  def self.recent(limit = nil)
    self.find(:all, :order => 'created_at desc, id desc', :limit => limit)
  end

  def notification_emails
    self.article.profile.notification_emails - [self.author_email || self.email]
  end

  def notification_rule_msg
    profile = self.article.profile if !self.article.profile.blank?
    if profile.organization?
      if profile.community?
        _("a comuninity which you are listed as contact email or you are an admin of its page")
      else
        _("an enterprise which you are listed as contact email or you are an admin of its page")
      end
    else
      _("your user profile")
    end
  end

  after_create :new_follower
  def new_follower
    if source.kind_of?(Article)
      article.followers += [author_email]
      article.followers -= article.profile.notification_emails
      article.followers.uniq!
      article.save
    end
  end

  after_create :schedule_notification

  def schedule_notification
    Delayed::Job.enqueue CommentHandler.new(self.id, :verify_and_notify)
  end

  delegate :environment, :to => :profile
  delegate :profile, :to => :source, :allow_nil => true

  include Noosfero::Plugin::HotSpot

  include Spammable

  def after_spam!
    SpammerLogger.log(ip_address, self)
    Delayed::Job.enqueue(CommentHandler.new(self.id, :marked_as_spam))
  end

  def after_ham!
    Delayed::Job.enqueue(CommentHandler.new(self.id, :marked_as_ham))
  end

  def verify_and_notify
    check_for_spam
    unless spam?
      notify_by_mail
    end
  end

  def notify_by_mail
    if source.kind_of?(Article) && article.notify_comments?
      if !notification_emails.empty?
        Comment::Notifier.deliver_mail(self)
      end
      emails = article.followers - [author_email]
      if !emails.empty?
        Comment::Notifier.deliver_mail_to_followers(self, emails)
      end
    end
  end

  after_create do |comment|
    if comment.source.kind_of?(Article)
      comment.article.create_activity if comment.article.activity.nil?
      if comment.article.activity
        comment.article.activity.increment!(:comments_count)
        comment.article.activity.update_attribute(:visible, true)
      end
    end
  end

  after_destroy do |comment|
    comment.article.activity.decrement!(:comments_count) if comment.source.kind_of?(Article) && comment.article.activity
  end

  def replies
    @replies || children
  end

  def replies=(comments_list)
    @replies = comments_list
  end

  include ApplicationHelper
  def reported_version(options = {})
    comment = self
    lambda { render_to_string(:partial => 'shared/reported_versions/comment', :locals => {:comment => comment}) }
  end

  def to_html(option={})
    body || ''
  end

  class Notifier < ActionMailer::Base
    def mail(comment)
      profile = comment.article.profile
      recipients comment.notification_emails
      from "#{profile.environment.name} <#{profile.environment.contact_email}>"
      subject _("[%s] you got a new comment!") % [profile.environment.name]
      body :recipient => comment.article.profile.short_name(200),
        :sender => comment.author_name,
        :sender_link => comment.author_link,
        :article_title => comment.article.name,
        :comment_url => comment.url,
        :comment_title => comment.title,
        :comment_body => comment.body,
        :environment => profile.environment.name,
        :url => profile.environment.top_url,
        :notification_rule_msg => comment.notification_rule_msg      
    end
    def mail_to_followers(comment, emails)
      profile = comment.article.profile
      bcc emails
      from "#{profile.environment.name} <#{profile.environment.contact_email}>"
      subject _("[%s] %s commented on a content of %s") % [profile.environment.name, comment.author_name, profile.short_name]
      body :recipient => profile.nickname || profile.name,
        :sender => comment.author_name,
        :sender_link => comment.author_link,
        :article_title => comment.article.name,
        :comment_url => comment.url,
        :unsubscribe_url => comment.article.view_url.merge({:unfollow => true}),
        :comment_title => comment.title,
        :comment_body => comment.body,
        :environment => profile.environment.name,
        :url => profile.environment.top_url
    end
  end

  def rejected?
    @rejected
  end

  def reject!
    @rejected = true
  end

  def need_moderation?
    article.moderate_comments? && (author.nil? || article.author != author)
  end

  def can_be_destroyed_by?(user)
    return if user.nil?
    user == author || user == profile || user.has_permission?(:moderate_comments, profile)
  end

  def can_be_marked_as_spam_by?(user)
    return if user.nil?
    user == profile || user.has_permission?(:moderate_comments, profile)
  end

  def can_be_updated_by?(user)
    user.present? && user == author
  end

end
