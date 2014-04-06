class ElectionSchedule < ActiveRecord::Base
  validates_presence_of :rank, :weekday, :month, :term_length, :start_year, :jurisdiction, :election_type, :source
  validates_inclusion_of :rank, in: -4..3
  validates_inclusion_of :weekday, in: 0..6
  validates_inclusion_of :month, in: 1..12
  validates_inclusion_of :jurisdiction, in: ['Canada'] + ComingElections::PROVINCES_AND_TERRITORIES
  validates_inclusion_of :election_type, in: ComingElections::ELECTION_TYPES
  validates_numericality_of :term_length, only_integer: true, greater_than: 0
  validates_numericality_of :start_year, only_integer: true

  rails_admin do
    list do
      field :jurisdiction
      field :rank
      field :weekday
      field :month
      field :term_length
      field :start_year
      field :source
      field :scope
      field :notes
      field :election_type
    end
  end

  # @param [Range] range a range of dates
  def self.within(range)
    all.map do |election_schedule|
      election = election_schedule.next_election(range.min)
      if election.valid? # fires before_validation callbacks
        if range.cover?(election.start_date) && range.cover?(election.end_date)
          election
        end
      else
        raise ActiveRecord::RecordInvalid.new(election)
      end
    end.compact
  end

  # @param [Date] date the start date
  # @return [Election] the next election
  def next_election(date = Date.today)
    Election.new(attributes.slice('jurisdiction', 'election_type', 'scope', 'notes', 'source').merge({
      start_date: next_election_date(date),
      scheduled: true,
    }))
  end

  # @param [Date] date the start date
  # @return [Date] the next election date
  def next_election_date(date = Date.today)
    year = this_or_next_election_year(date)

    if rank >= 0
      next_date = Date.new(year, month)
    else
      next_date = Date.new(year, month + 1)
    end

    next_date = next_date + next_date.days_to_week_start(weekday) + rank.weeks

    if next_date < date
      next_date = next_election_date(Date.new(year + 1))
    end

    next_date
  end

private

  def this_or_next_election_year(date = Date.today)
    date.year + date.years_to_term_start(start_year, term_length)
  end
end
