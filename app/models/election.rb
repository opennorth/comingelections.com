# coding: utf-8
require 'csv'

class Election < ActiveRecord::Base
  attr_accessible :year, :start_date, :end_date, :jurisdiction, :election_type, :division, :scope, :notes, :source

  before_validation :set_year, :set_end_date

  validates_presence_of :year, :start_date, :end_date, :jurisdiction, :election_type, :source
  validates_presence_of :division, if: :by_election?
  validates_inclusion_of :jurisdiction, in: [
    'Canada',
    # Provinces
    'Alberta',
    'British Columbia',
    'Manitoba',
    'New Brunswick',
    'Newfoundland and Labrador',
    'Nova Scotia',
    'Ontario',
    'Prince Edward Island',
    'Quebec',
    'Saskatchewan',
    # Territories
    'Northwest Territories',
    'Nunavut',
    'Yukon',
  ]
  validates_inclusion_of :election_type, in: %w(general by-election municipal)
  validate :end_date_must_be_after_start_date

  # @param [Integer] seconds seconds
  def self.within_next(seconds)
    where(start_date: Date.today..seconds.from_now.to_date)
  end

  # @param [Hash] attributes attributes
  def self.create_or_update(attributes)
    criteria = attributes.slice(:start_date, :jurisdiction, :election_type)
    election = Election.where(criteria).first_or_initialize
    election.assign_attributes(attributes)
    election.save!
  end

  # @return [String] the list of elections as a CSV file
  def self.to_csv
    CSV.generate(row_sep: "\r\n") do |csv|
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

  def end_date_must_be_after_start_date
    if end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end

  def by_election?
    election_type == "by-election"
  end
end
