class AddMonthToElectionSchedule < ActiveRecord::Migration
  def change
    add_column :election_schedules, :month, :integer
  end
end
