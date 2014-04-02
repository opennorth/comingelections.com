class AlertMailer < ActionMailer::Base
  default from: 'alerts@opennorth.ca'

  def notify(elections)
    @elections = elections
    User.where(notify: true).each do |user|
      mail(to: user.email)
    end
  end
end
