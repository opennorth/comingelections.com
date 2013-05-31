namespace :scheduler do
  desc 'Run the scrapers'
  task :scrape do
    Rake::Task['scrape:public_service_commission'].invoke
    Rake::Task['scrape:wikipedia'].invoke
    Rake::Task['scrape:muniscope'].invoke
  end

  desc 'Alert administrators of elections in the next week each Sunday'
  task alert: :environment do
    if Date.today.sunday?
      range = Date.today..1.week.from_now.to_date
      elections = Election.within(range) + ElectionSchedule.within(range)
      unless elections.empty?
        AlertMailer.notify(elections).deliver
      end
    end
  end
end
