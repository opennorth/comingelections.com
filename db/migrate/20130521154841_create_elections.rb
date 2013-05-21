class CreateElections < ActiveRecord::Migration
  def change
    create_table :elections do |t|
      t.integer :year
      t.date :start_date
      t.date :end_date
      t.string :jurisdiction
      t.string :election_type
      t.string :scope
      t.string :division
      t.string :notes
      t.string :source
      t.datetime :updated_at

      t.timestamps
    end
  end
end
