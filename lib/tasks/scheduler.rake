namespace :scheduler do
  desc "run scrapers once per week"
  task :scrape do
    if Time.now.wday == 3 then
      Rake::Task['scrape:govt'].invoke 
      Rake::Task['scrape:wiki'].invoke 
      Rake::Task['scrape:muni'].invoke 
      Rake::Task['scrape:db'].invoke
    end
  end
end
