class CreateStores < Sequel::Migration
  def up
    create_table :stores do
      primary_key :id
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      varchar :categories, :null => false
      varchar :name, :null => false
      datetime :created_at, :null => false
      datetime :updated_at, :null => false
    end
    
    add_column :saved_lists, :store_id, :integer
    DB << "alter table saved_lists add foreign key fk_saved_lists_stores (store_id) references stores (id) on delete set null"
  end
  
  def down
    drop_table :stores
    remove_column :saved_lists, :store_id
  end
end