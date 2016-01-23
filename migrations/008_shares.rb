class Shares < Sequel::Migration
  def up
    create_table :recipe_shares do
      primary_key :id
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      char :rand, :size => 20, :null => false
      varchar :email, :null => false
      varchar :message, :size => 1024
      datetime :viewed_at
      datetime :created_at, :null => false
      
      index :rand, :unique => true
    end
  end
  
  def down
    drop_table :recipe_shares
  end
end