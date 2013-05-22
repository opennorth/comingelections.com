class Election < ActiveRecord::Base

  attr_accessible :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source

  attr_accessor :date

  before_create :set_dates 

  def self.create_or_update(attributes)
    criteria = attributes.slice(:start_date,:jurisdiction,:election_type)   
    election = Election.where(criteria).first_or_initialize
    election.assign_attributes(attributes.slice(:year,:end_date,:scope,:division,:notes,:source))
    p election
    election.save!
#      puts election.inspect
  end

  def self.to_csv 
    @col_sep = ',' 
    CSV.generate(:col_sep => @col_sep, :row_sep => "\r\n",:headers => :first_row) do |csv|
      csv << ["id","year","start_date","end_date","division","election_type"]
      self.all.each do |election|
        begin
          csv << election.attributes.values_at("id","year","start_date","end_date","division","election_type")
        rescue ArgumentError => e # non-UTF8 characters from spammers
          logger.error "#{e.inspect}: #{row.inspect}"
        end
      end
    end.html_safe
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

