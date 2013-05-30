require 'spec_helper'

describe ElectionSchedule do
  let (:attributes) do
    {
      :base_year => 2005,
      :month => 5,
      :rank => 2,
      :term_length => 4,
      :weekday => 2,
    }
  end
  context 'creating an election_schedule' do
    it 'should create an election schedule' do
      lambda{
        ElectionSchedule.create(attributes)
      }.should change(ElectionSchedule, :count).by(1)
    end

    it 'should not allow rank to be 0' do
      attributes[:rank] = 0
      lambda{
        ElectionSchedule.create(attributes)
      }.should_not change(ElectionSchedule, :count)
    end

  end

  context 'finding next election' do
    it 'should find the right date' do
      bc = ElectionSchedule.create(attributes)
      bc.next_election(bc.base_year).should == Date.parse("May 12, 2009")
    end

    it 'should find the right date without any parameters' do
      bc = ElectionSchedule.create(attributes)
      bc.next_election.should == Date.parse("May 12, 2009")
    end

    it 'should find the last (x) weekday' do
      attributes[:rank] = -1
      bc = ElectionSchedule.create(attributes)
      bc.next_election(bc.base_year).should == Date.parse("May 26, 2009")
    end
  end
end
