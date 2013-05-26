require 'csv'

class Election < ActiveRecord::Base

  attr_accessible :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source

  attr_accessor :date

  before_save :set_year
  before_save :set_end_date

  def self.create_or_update(attributes)
    criteria = attributes.slice(:start_date, :jurisdiction, :election_type)
    election = Election.where(criteria).first_or_initialize
    election.assign_attributes(attributes.slice(:year, :end_date, :scope, :division, :notes, :source))
    election.save!
  end

  def self.to_csv
    @col_sep = ','
    CSV.generate(col_sep: @col_sep, row_sep: "\r\n", headers: :first_row) do |csv|
      csv << ["id","year","start_date","end_date","jurisdiction","division","election_type","scope","notes","source"]
      self.all.each do |election|
        begin
          csv << election.attributes.values_at("id","year","start_date","end_date","jurisdiction","division","election_type","scope","notes","source")
        rescue ArgumentError => e # non-UTF8 characters from spammers
          logger.error "#{e.inspect}: #{row.inspect}"
        end
      end
    end.html_safe
  end

private

  def set_year
    if start_date_changed?
      self.year = start_date.year
    end
  end

  def set_end_date
    if start_date_changed?
      if end_date.blank? || end_date == start_date_was
        self.end_date = start_date
      end
    end
  end
end
