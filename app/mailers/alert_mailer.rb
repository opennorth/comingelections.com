class AlertMailer < ActionMailer::Base
  default from: "alerts@opennorth.ca"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.alert_mailer.notify.subject
  #
  def notify(elections)
    @elections = elections
    mail(to: ENV['ALERT_EMAILS'], subject: "elctions this week")

    

  end
end
