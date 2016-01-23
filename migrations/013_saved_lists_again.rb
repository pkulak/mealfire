class SavedListsAgain < Sequel::Migration
  def up
    # Undo the old saved lists.
    DB << 'delete from ingredients where ingredient_group_id is null'
    DB << 'alter table ingredients modify ingredient_group_id integer'
    DB << 'alter table ingredients drop foreign key ingredients_ibfk_3'
    
    drop_column :ingredients, :saved_list_id
    drop_column :ingredients, :deleted
    
    drop_table :saved_lists
    
    # And make our new tables.
    create_table :saved_lists do
      primary_key :id
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      datetime :created_at, :null => false
      varchar :days, :size => 1024
    end
    
    create_table :saved_foods do
      primary_key :id
      foreign_key :saved_list_id, :saved_lists, :key => :id, :on_delete => :cascade, :null => false
      varchar :name
    end
  end
end