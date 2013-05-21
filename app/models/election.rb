class Election < ActiveRecord::Base
  attr_accessible :scope, :division, :election_type, :end_date, :jurisdiction, :notes, :source, :start_date, :updated_at, :year
end
