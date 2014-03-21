class Mailing < ActiveRecord::Base

  validates_presence_of :source_id, :subject, :body
  belongs_to :source, :foreign_key => :source_id, :polymorphic => true
  belongs_to :person

  has_many :mailing_sents

  xss_terminate :only => [ :subject, :body ], :with => 'white_list', :on => 'validation'

  after_create do |mailing|
    mailing.schedule
  end

  def schedule
    Delayed::Job.enqueue MailingJob.new(self.id)
  end

  def generate_from
    "#{source.name} <#{if source.is_a? Environment then source.noreply_email else source.contact_email end}>"
  end

  def generate_subject
    '[%s] %s' % [source.name, subject]
  end

  def signature_message
    _('Sent by Noosfero.')
  end

  def url
    ''
  end

  def deliver
    each_recipient do |recipient|
      begin
        Mailing::Sender.deliver_mail(self, recipient.email)
        self.mailing_sents.create(:person => recipient)
      rescue Exception
        # FIXME should not discard errors silently. An idea is to collect all
        # errors and generate a task (notification) for the +source+
        # (environment/organization) listing these errors.
      end
    end
  end

  class Sender < ActionMailer::Base
    def mail(mailing, recipient)
      content_type 'text/html'
      recipients recipient
      from mailing.generate_from
      reply_to mailing.person.email
      subject mailing.generate_subject
      body :message => mailing.body,
        :signature_message => mailing.signature_message,
        :url => mailing.url
    end
  end
end
