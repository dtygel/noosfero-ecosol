class ChangePassword < Task

  attr_accessor :login, :email, :password, :password_confirmation, :environment_id
  
  # FIXME ugly workaround
  def self.human_attribute_name(attrib)
    case attrib.to_sym
    when :login:  return _('Username') + ' ' + _('or') + ' ' + _('Email')
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
  
  # FIXME ugly substitute for find_by_login_and_environment_id
  def self.find_by_login_or_email_and_environment_id(login, environment_id = nil)
    environment_id ||= Environment.default.id
    User.first :conditions => ['(login = ? OR email = ?) AND environment_id = ?', login, login, environment_id]
  end

  ###################################################
  # validations for creating a ChangePassword task 
  
  validates_presence_of :login, :environment_id, :on => :create, :message => _('must be filled in')

  validates_each :login, :on => :create do |data,attr,value|
    unless data.login.blank?
      user = self.find_by_login_or_email_and_environment_id(data.login, data.environment_id)
      if user.nil? 
        data.errors.add(:login, _('is invalid or user does not exists.'))
      end
    end
  end

  before_validation_on_create do |change_password|
    u = change_password.class.find_by_login_or_email_and_environment_id(change_password.login, change_password.environment_id)
    change_password.requestor = (u.nil?) ? nil : u.person
  end

  ###################################################
  # validations for updating a ChangePassword task 

  # only require the new password when actually changing it.
  validates_presence_of :password, :on => :update, :if => lambda { |change| change.status != Task::Status::CANCELLED }
  validates_presence_of :password_confirmation, :on => :update, :if => lambda { |change| change.status != Task::Status::CANCELLED }
  validates_confirmation_of :password, :if => lambda { |change| change.status != Task::Status::CANCELLED }

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

end
