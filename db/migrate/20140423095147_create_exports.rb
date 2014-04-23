class CreateExports < ActiveRecord::Migration
  def change
    create_table :exports do |t|
      t.references :user
      t.text :output
      t.boolean :success, :default => false
      t.string :file
      t.timestamps
      t.timestamp :finished_at
    end
  end
end
