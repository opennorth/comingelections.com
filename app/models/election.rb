require 'csv'

class Election < ActiveRecord::Base
  attr_accessible :year, :start_date, :end_date, :jurisdiction, :division, :election_type, :scope, :notes, :source

  before_validation :set_year, :set_end_date

  validates :year, :start_date, :end_date, :jurisdiction, :election_type, :source, :presence => true

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
end
