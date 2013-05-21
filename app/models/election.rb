class Election < ActiveRecord::Base

  attr_accessible :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source

  before_create do 
    Election.find_all_by_start_date(self.start_date).each do |e|
      if e.jurisdiction == self.jurisdiction && e.election_type == self.election_type then
        return false 
      end
    end
  end
end
