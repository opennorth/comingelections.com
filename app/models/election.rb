class Election < ActiveRecord::Base

  attr_accessible :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source

  attr_accessor :date

  before_create :set_dates

  before_create do 
    Election.find_all_by_start_date(self.start_date).each do |e|
      if e.jurisdiction == self.jurisdiction && e.election_type == self.election_type then
        return false 
      end
    end
  end

private

  def set_dates
    if date
      self.year = date.year
      self.start_date = date
      self.end_date = date
    end
  end
end
