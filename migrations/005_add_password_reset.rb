class AddPasswordReset < Sequel::Migration
  def up
    create_table :password_resets do
      primary_key :id
      foreign_key :authed_user_id, :authed_users, :key => :id, :null => false, :on_delete => :cascade
      char :rand, :null => false, :size => 10
      bool :followed, :null => false, :default => false
      datetime :created_at, :null => false
      
      index :authed_user_id
    end
  end
  
  def down
    drop_table :password_resets
  end
end