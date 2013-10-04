require_dependency 'person'

class Person
  validates_uniqueness_of :usp_id, :allow_nil => true
  settings_items :invitation_code
  validate :usp_id_or_invitation, :if => lambda { |person| person.environment && person.environment.plugin_enabled?(StoaPlugin)}

  before_validation do |person|
    person.usp_id = nil if person.usp_id.blank?
  end

  def usp_id_or_invitation
    if usp_id.blank? && !is_template && (invitation_code.blank? || !invitation_task)
      errors.add(:usp_id, _("is being used by another user or is not valid"))
    end
  end

  def invitation_task
    Task.pending.find(:first, :conditions => {:code => invitation_code.to_s}) ||
    Task.finished.find(:first, :conditions => {:code => invitation_code.to_s, :target_id => id})
  end
end
