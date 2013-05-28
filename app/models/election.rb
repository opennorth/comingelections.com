require 'csv'

class Election < ActiveRecord::Base
  attr_accessible :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source

  before_validation :set_year, :set_end_date

  validates_presence_of :year, :start_date, :end_date, :jurisdiction, :election_type, :source
  validates_presence_of :division, :if => :by_election?
  validate :validate_dates

  def self.create_or_update(attributes)
    criteria = attributes.slice(:start_date, :jurisdiction, :election_type)
    election = Election.where(criteria).first_or_initialize
    election.assign_attributes(attributes.slice(:year, :end_date, :scope, :division, :notes, :source))
    election.save
  end

  def self.to_csv
    CSV.generate(row_sep: "\r\n", headers: :first_row) do |csv|
      csv << ['id', 'year', 'start_date', 'end_date', 'jurisdiction', 'division', 'election_type', 'scope', 'notes', 'source']
      all.each do |election|
        csv << election.attributes.values_at(:id, :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source)
      end
    end
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

  def validate_dates
    errors.add("End Date", "is invalid") if end_date < start_date
  end

  def by_election?
      election_type == "by-election"
  end
end
