class Ratings < Sequel::Migration
  def up
    create_table :ratings do
      primary_key :id
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      foreign_key :recipe_day_id, :recipe_days, :key => :id, :unique => true, :on_delete => :set_null
      float :value, :null => false
      datetime :created_at, :null => false
    end
    
    add_column :recipe_days, :is_rated, :boolean, default: false, null: false
    add_column :authed_users, :rate_recipes, :boolean, default: true, null: false
    add_column :recipes, :rating, :float
  end
  
  def down
    drop_table :ratings
  end
end