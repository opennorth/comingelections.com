require 'spec_helper'

describe Election do
  context 'when creating a record' do
    let :election do
      FactoryGirl.build(:election).attributes.with_indifferent_access
    end

    it 'should set the year to match the start date' do
      Election.create_or_update(election)
      Election.last.year.should == election[:start_date].year
    end

    it 'should set the end date to match the start date if the end date is empty' do
      Election.create_or_update(election)
      Election.last.end_date.should == election[:start_date]
    end

  end

  context 'when updating a record' do
    
    let :election do 
      FactoryGirl.build(:election).attributes.with_indifferent_access
    end

    let :with_same_end_date do
      FactoryGirl.build(:with_same_end_date).attributes.with_indifferent_access
    end

    let :with_different_end_date do
      FactoryGirl.build(:with_different_end_date).attributes.with_indifferent_access
    end

    let :with_extra_info do
      FactoryGirl.build(:with_extra_info).attributes.with_indifferent_access
    end

    before do 
      Election.create_or_update(election)
    end

    it 'should set the year to match the start date' do
      Election.create_or_update(with_extra_info)
      revised = Election.order("updated_at").last
      revised.year.should == with_extra_info[:start_date].year
    end

    it 'should set the end date to match the start date if the end date is empty' do
      Election.create_or_update(with_extra_info)
      revised = Election.order("updated_at").last
      revised.end_date.should == election[:start_date]
    end

    it 'should set the end date to match the start date if the end date was equal to the start date' do
      Election.create_or_update(with_same_end_date)
      revised = Election.order("updated_at").last
      revised.end_date.should == election[:start_date]
    end

    it 'should not set the end date to match the start date if the end date was different from the start date' do
      Election.create_or_update(with_different_end_date)
      revised = Election.order("updated_at").last
      revised.end_date.should == with_different_end_date[:end_date]
    end

    it 'should update fields that are different' do
      Election.create_or_update(with_extra_info)
      revised = Election.order("updated_at").last
      p with_extra_info
      p Election.all
      revised.scope.should == with_extra_info[:scope]
      revised.notes.should == with_extra_info[:notes]
    end

  end
end
