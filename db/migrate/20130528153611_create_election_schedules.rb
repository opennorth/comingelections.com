class CreateElectionSchedules < ActiveRecord::Migration
  def change
    create_table :election_schedules do |t|
      t.integer :rank
      t.integer :weekday
      t.integer :month
      t.integer :term_length
      t.integer :start_year
      t.string :jurisdiction
      t.string :election_type
      t.string :scope
      t.string :notes
      t.string :source

      t.timestamps
    end
  end
end
