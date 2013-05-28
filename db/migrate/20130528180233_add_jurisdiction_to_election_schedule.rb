class AddJurisdictionToElectionSchedule < ActiveRecord::Migration
  def change
    add_column :election_schedules, :jurisdiction, :string
  end
end
