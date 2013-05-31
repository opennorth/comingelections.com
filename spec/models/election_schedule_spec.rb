require 'spec_helper'

describe ElectionSchedule do
  let :attributes do
    {
      rank: 0,
      weekday: 0,
      month: 1,
      term_length: 7,
      start_year: 1919,
      jurisdiction: 'Canada',
      election_type: 'general',
      scope: 'foo',
      notes: 'bar',
      source: 'http://example.com/',
    }
  end

  describe '#within' do
    pending
  end

  describe '#next_election' do
    it 'should return the next election' do
      election = ElectionSchedule.new(attributes).next_election(Date.new(1930))
      election.start_date.should == Date.new(1933, 1, 1)
      election.jurisdiction.should == 'Canada'
      election.election_type.should == 'general'
      election.scope.should == 'foo'
      election.notes.should == 'bar'
      election.source.should == 'http://example.com/'
      election.scheduled.should == true
      election.valid?.should == true
    end
  end

  describe '#next_election_date' do
    it 'should return the correct next election date in a non-election year' do
      [
        [{rank: -4}, Date.new(1933, 1, 8)],
        [{rank: -3}, Date.new(1933, 1, 15)],
        [{rank: -2}, Date.new(1933, 1, 22)],
        [{rank: -1}, Date.new(1933, 1, 29)],
        [{rank: 0}, Date.new(1933, 1, 1)],
        [{rank: 1}, Date.new(1933, 1, 8)],
        [{rank: 2}, Date.new(1933, 1, 15)],
        [{rank: 3}, Date.new(1933, 1, 22)],

        [{weekday: 0}, Date.new(1933, 1, 1)],
        [{weekday: 1}, Date.new(1933, 1, 2)],
        [{weekday: 2}, Date.new(1933, 1, 3)],
        [{weekday: 3}, Date.new(1933, 1, 4)],
        [{weekday: 4}, Date.new(1933, 1, 5)],
        [{weekday: 5}, Date.new(1933, 1, 6)],
        [{weekday: 6}, Date.new(1933, 1, 7)],

        [{month: 1}, Date.new(1933, 1, 1)],
        [{month: 2}, Date.new(1933, 2, 5)],
        [{month: 3}, Date.new(1933, 3, 5)],
        [{month: 4}, Date.new(1933, 4, 2)],
        [{month: 5}, Date.new(1933, 5, 7)],
        [{month: 6}, Date.new(1933, 6, 4)],
        [{month: 7}, Date.new(1933, 7, 2)],
        [{month: 8}, Date.new(1933, 8, 6)],
        [{month: 9}, Date.new(1933, 9, 3)],
        [{month: 10}, Date.new(1933, 10, 1)],
        [{month: 11}, Date.new(1933, 11, 5)],
        [{month: 12}, Date.new(1933, 12, 3)],
      ].each do |hash,expected|
        ElectionSchedule.new(attributes.merge(hash)).next_election_date(Date.new(1930)).should == expected
      end
    end

    it 'should return the correct next election date in an election year' do
      [
        [{month: 1}, Date.new(1933, 1, 1)],
        [{month: 2}, Date.new(1933, 2, 5)],
        [{month: 3}, Date.new(1933, 3, 5)],
        [{month: 4}, Date.new(1933, 4, 2)],
        [{month: 5}, Date.new(1933, 5, 7)],
        [{month: 6}, Date.new(1933, 6, 4)],

        [{month: 7}, Date.new(1926, 7, 4)],
        [{month: 8}, Date.new(1926, 8, 1)],
        [{month: 9}, Date.new(1926, 9, 5)],
        [{month: 10}, Date.new(1926, 10, 3)],
        [{month: 11}, Date.new(1926, 11, 7)],
        [{month: 12}, Date.new(1926, 12, 5)],
      ].each do |hash,expected|
        ElectionSchedule.new(attributes.merge(hash)).next_election_date(Date.new(1926, 7, 1)).should == expected
      end
    end
  end
end
