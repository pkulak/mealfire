class Categories < Sequel::Migration
  def up
    create_table :categories do
      primary_key :id
      varchar :name
    end
    
    create_table :category_finders do
      primary_key :id
      foreign_key :category_id, :categories, :key => :id, :null => false
      varchar :expression, :null => false
    end
    
    Category.add_data
  end
  
  def down
    drop_table :category_finders
    drop_table :categories
  end
end