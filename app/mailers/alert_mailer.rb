class AlertMailer < ActionMailer::Base
  default from: 'alerts@opennorth.ca'

  def notify(elections)
    @elections = elections
    mail(to: ENV['ALERT_EMAILS'])
  end
end
