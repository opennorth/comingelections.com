class CreateElectionSchedules < ActiveRecord::Migration
  def change
    create_table :election_schedules do |t|
      t.integer :rank
      t.integer :weekday
      t.integer :month
      t.integer :term_length
      t.date    :last_election
      t.string  :jurisdiction

      t.timestamps
    end
  end
end
