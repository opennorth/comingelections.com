class AddLastElectionToElectionSchedule < ActiveRecord::Migration
  def change
    add_column :election_schedules, :last_election, :datetime
  end
end
