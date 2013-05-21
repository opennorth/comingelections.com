class CreateElections < ActiveRecord::Migration
  # @see https://github.com/openelections/specs/wiki/Elections-Data-Spec-Version-2
  def change
    create_table :elections do |t|
      t.integer :year
      t.date :start_date
      t.date :end_date
      t.string :jurisdiction
      t.string :division
      t.string :election_type
      t.string :scope
      t.string :notes
      t.string :source

      t.timestamps
    end
  end
end
