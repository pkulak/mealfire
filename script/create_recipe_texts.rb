require File.expand_path('../app.rb', File.dirname(__FILE__))
require 'sequel/extensions/migration'

class AddSearch < Sequel::Migration
  def up
    Sequel::MySQL.default_engine = 'MyISAM'
    
    create_table :recipe_texts do
      primary_key :id
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      text :data
      index :recipe_id
    end
    
    RecipeText.columns
    
    Sequel::MySQL.default_engine = 'InnoDB'
    
    DB << "alter table recipe_texts character set = utf8;"
    DB << 'alter table recipe_texts modify column `data` text CHARACTER SET utf8'
    DB << 'alter table recipe_texts add fulltext (data)'
    
    Recipe.each do |recipe|
      RecipeText.index_recipe(recipe)
    end
  end
  
  def down
    drop_table :recipe_texts
  end
end

AddSearch.apply(DB, :up)