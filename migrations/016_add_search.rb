class AddSearch < Sequel::Migration
  def up
    Sequel::MySQL.default_engine = 'MyISAM'
    
    create_table :recipe_texts do
      primary_key :id
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      text :data
      index :recipe_id
    end
    
    Sequel::MySQL.default_engine = 'InnoDB'
    
    DB << 'alter table recipe_texts add fulltext (data)'
  end
  
  def down
  end
end