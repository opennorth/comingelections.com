require 'spec_helper'

describe Election do
  let :attributes do
    {
      :start_date => Date.parse("October 1, 2015"),
      :jurisdiction => "Ontario",
      :election_type => "Provincial",
      :scope => '',
      :source => 'http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm',
    }
  end
  context 'when creating a record' do
    
    it 'should create a new record' do
      lambda{
        Election.create_or_update(attributes)
      }.should change(Election, :count).by(1)
    end
    
    it 'should set the year to match the start date' do
      Election.create_or_update(attributes)
      Election.last.year.should == attributes[:start_date].year
    end

    it 'should set the end date to match the start date if the end date is empty' do
      Election.create_or_update(attributes)
      Election.last.end_date.should == attributes[:start_date]
    end

  end

  context 'when updating a record' do
    
    let :extra_info do 
      {
        :scope => 'sample scope',
        :notes => 'here is some sample info'
      }
    end

    before do 
      Election.create_or_update(attributes)
    end

    it 'should not create a new record' do 
      lambda{
        Election.create_or_update(attributes.merge(extra_info))
      }.should_not change(Election, :count)
    end

    it 'should set the year to match the start date' do
      Election.create_or_update(attributes.merge(extra_info))
      revised = Election.order("updated_at").last
      revised.year.should == attributes[:start_date].year
    end

    it 'should set the end date to match the start date if the end date is empty' do
      Election.create_or_update(attributes)
      revised = Election.order("updated_at").last
      revised.end_date.should == attributes[:start_date]
    end

    it 'should set the end date to match the start date if the end date was equal to the start date' do
      Election.create_or_update(attributes.merge({:end_date => Date.parse("October 1, 2015")}))
      revised = Election.order("updated_at").last
      revised.end_date.should == attributes[:start_date]
    end

    it 'should not set the end date to match the start date if the end date was different from the start date' do
      Election.create_or_update(attributes.merge({:end_date => Date.parse("October 3, 2015")}))
      revised = Election.order("updated_at").last
      revised.end_date.should == Date.parse("October 3, 2015")
    end

    it 'should update fields that are different' do
      Election.create_or_update(attributes.merge(extra_info))
      revised = Election.order("updated_at").last
      revised.scope.should == extra_info[:scope]
      revised.notes.should == extra_info[:notes]
    end

  end
end
