class CreateElectionSchedules < ActiveRecord::Migration
  def change
    create_table :election_schedules do |t|
      t.integer :rank
      t.integer :weekday
      t.integer :mont
      t.integer :term_length

      t.timestamps
    end
  end
end
