class CreateParkings < ActiveRecord::Migration[8.0]
  def change
    create_table :parkings, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :status, null: false, default: "available"
      t.string :phone_number
      t.timestamps
    end
  end
end
