class CreateDiscussions < ActiveRecord::Migration[8.1]
  def change
    create_table :discussions do |t|
      t.string :title, null: false

      t.timestamps
    end
  end
end
