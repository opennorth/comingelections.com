class ElectionSchedule < ActiveRecord::Base
  attr_accessible :month, :rank, :term_length, :weekday, :last_election, :jurisdiction

  validates_presence_of :month, :rank, :term_length, :weekday, :last_election
  validate :valid_rank

  SOURCE = 'http://en.wikipedia.org/wiki/Fixed_election_dates_in_Canada'

  def elections_until (year)
    elections = []
    previous = last_election
    num = (year-last_election.year)/term_length
    num.times do
      upcoming = next_election(previous)
      elections.push(upcoming)
      previous = upcoming
    end
    elections
  end

  def next_election (previous = self.last_election)
    year = previous.year + term_length
    if rank > 0
      date = Date.parse("#{year}-#{month}-1")
      date = date + (7-(date.wday-weekday)%7).days
      date = date + (rank-1).weeks
    else
      date = Date.parse("#{year}-#{month+1}-1")
      date = date + (7-(date.wday-weekday)%7).days
      date = date + (rank).weeks
    end
  end

private
  def valid_rank  
    errors.add("Rank","can't be 0") if rank == 0
  end
end
