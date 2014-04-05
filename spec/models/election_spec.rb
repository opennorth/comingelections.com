require 'spec_helper'

describe Election do
  let :attributes do
    {
      start_date: Date.new(1920, 1, 1),
      jurisdiction: 'Canada',
      election_type: 'general',
      source: 'http://example.com/',
    }
  end

  describe '#within' do
    it 'should return the elections within the range' do
      a = Election.create(attributes.merge(start_date: Date.new(1950, 1, 1)))
      b = Election.create(attributes.merge(start_date: Date.new(1900, 1, 1)))
      c = Election.create(attributes)
      d = Election.create(attributes)
      Election.within(Date.new(1910)..Date.new(1930)).should == [c, d]
    end
  end

  describe '#create_or_update' do
    it 'should create a new record' do
      expect{
        Election.create_or_update(attributes)
      }.to change(Election, :count).by(1)
    end

    it 'should update a record if a match is found' do
      expect{
        election = Election.create(attributes)
        Election.create_or_update(attributes.merge(notes: 'Foo'))
      }.to change(Election, :count).by(1)
    end

    it 'should not update a record if a match is not found' do
      expect{
        election = Election.create(attributes)
        Election.create_or_update(attributes.merge(election_type: 'municipal'))
      }.to change(Election, :count).by(2)
    end

    it 'should raise an error if the record is invalid' do
      expect{
        Election.create_or_update(attributes.merge(election_type: 'foo'))
      }.to raise_error
    end
  end

  describe 'callbacks' do
    let :election do
      Election.create(attributes)
    end

    let :election_with_end_date do
      Election.create(attributes.merge(end_date: Date.new(1920, 1, 2)))
    end

    context 'when creating a record' do
      it 'should set the year to match the start date' do
        election.year.should == 1920
      end

      it 'should set the end date to match the start date if the end date is empty' do
        election.end_date.should == Date.new(1920, 1, 1)
      end
      it 'should not set the end date to match the start date if the end date is not empty' do
        election_with_end_date.end_date.should == Date.new(1920, 1, 2)
      end

      it 'should require the end date to be after the start date' do
        election = Election.create(attributes.merge(end_date: Date.new(1900, 1, 1)))
        election.should have(1).error_on(:end_date)
      end

      it 'should require the division to be present if it is a by-election' do
        election = Election.create(attributes.merge(election_type: 'by-election'))
        election.should have(1).error_on(:division)
      end
    end

    context 'when updating a record' do
      it 'should update the year to match the start date if changed' do
        election.update_attributes(start_date: Date.new(1925, 1, 1))
        election.year.should == 1925
      end
      it 'should not update the year to match the start date if not changed' do
        election.update_attributes(notes: 'Foo')
        election.year.should == 1920
      end

      it 'should update the end date to match the start date if changed' do
        election.update_attributes(start_date: Date.new(1925, 1, 1))
        election.end_date.should == Date.new(1925, 1, 1)
      end
      it 'should not update the end date to match the start date if not changed' do
        election.update_attributes(notes: 'Foo')
        election.end_date.should == Date.new(1920, 1, 1)
      end

      it 'should update the end date to match the start date if the end date was equal to the start date' do
        election.update_attributes(start_date: Date.new(1925, 1, 1))
        election.end_date.should == Date.new(1925, 1, 1)
      end
      it 'should not update the end date to match the start date if the end date was not equal to the start date' do
        election.update_attributes(start_date: Date.new(1925, 1, 1))
        election_with_end_date.end_date.should == Date.new(1920, 1, 2)
      end
    end
  end
end
