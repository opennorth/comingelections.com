require 'date'
namespace :scheduler do
  desc "run scrapers once per week"
  task :scrape do
    if Time.now.wday == 3 then
      Rake::Task['scrape:govt'].invoke 
      Rake::Task['scrape:wiki'].invoke 
      Rake::Task['scrape:muni'].invoke 
    end
  end
  task :alert => :environment do 
    if Time.now.wday == 1 then
      elections = Election.where(
        :start_date => (Time.now.to_date..(Time.now+(7*24*60*60)).to_date))
      unless elections.empty?
        AlertMailer.notify(elections).deliver
      end
    end
  end
end
