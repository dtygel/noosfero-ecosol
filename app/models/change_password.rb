class ChangePassword < Task

  attr_accessor :login, :password, :password_confirmation, :environment_id

  def self.human_attribute_name(attrib)
    case attrib.to_sym
    when :login:
      [_('Username'), _('Email')].join(' / ')
    when :email
      _('e-mail')
    when :password
      _('Password')
    when :password_confirmation
      _('Password Confirmation')
    else
      _(self.superclass.human_attribute_name(attrib))
    end
  end

  ###################################################
  # validations for creating a ChangePassword task

  validates_presence_of :login, :environment_id, :on => :create, :message => _('must be filled in')

  validate :valid_login, :on => :create

  before_validation_on_create do |change_password|
    user = self.user_from_login(change_password.login, change_password.environment_id)
    change_password.requestor = user.nil? ? nil : user.person
  end

  ###################################################
  # validations for updating a ChangePassword task

  # only require the new password when actually changing it.
  validates_presence_of :password, :on => :update, :if => lambda { |change| change.status != Task::Status::CANCELLED }
  validates_presence_of :password_confirmation, :on => :update, :if => lambda { |change| change.status != Task::Status::CANCELLED }
  validates_confirmation_of :password, :if => lambda { |change| change.status != Task::Status::CANCELLED }

  def self.user_from_login login, environment_id
    return nil if login.nil?

    if login.include?'@'
      user = User.find_by_email_and_environment_id(login, environment_id)
    else
      user = User.find_by_login_and_environment_id(login, environment_id)
    end
  end

  def title
    _("Change password")
  end

  def information
    {:message => _('%{requestor} wants to change its password.')}
  end

  def icon
    {:type => :profile_image, :profile => requestor, :url => requestor.url}
  end

  def perform
    user = self.requestor.user
    user.force_change_password!(self.password, self.password_confirmation)
  end

  def target_notification_description
    _('%{requestor} wants to change its password.') % {:requestor => requestor.name}
  end

  # overriding messages

  def task_cancelled_message
    _('Your password change request was cancelled at %s.') % Time.now.to_s
  end

  def task_finished_message
    _('Your password was changed successfully.')
  end

  include ActionController::UrlWriter
  def task_created_message
    hostname = self.requestor.environment.default_hostname
    code = self.code
    url = url_for(:host => hostname, :controller => 'account', :action => 'new_password', :code => code)

    lambda do
      _("In order to change your password, please visit the following address:\n\n%s") % url
    end
  end

  def environment
    self.requestor.environment
  end

  protected

  def valid_login
    unless self.login.blank?
      user = self.class.user_from_login(self.login, self.environment_id)
      if user.nil?
        self.errors.add(:login, _('is invalid or user does not exists.'))
      end
    end
  end

end
