class SavedLists < Sequel::Migration
  def up
    create_table :saved_lists do
      primary_key :id
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      datetime :created_at, :null => false
    end
    
    DB << "alter table ingredients modify ingredient_group_id integer null"
    
    add_column :ingredients, :saved_list_id, :integer
    add_column :ingredients, :deleted, :boolean, :null => false, :default => false
    
    DB << "alter table ingredients add constraint ingredients_ibfk_3 foreign key (saved_list_id) references saved_lists (id) on delete cascade"
  end
end