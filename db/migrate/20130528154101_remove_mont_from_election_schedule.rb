class RemoveMontFromElectionSchedule < ActiveRecord::Migration
  def up
    remove_column :election_schedules, :mont
  end

  def down
    add_column :election_schedules, :mont, :integer
  end
end
