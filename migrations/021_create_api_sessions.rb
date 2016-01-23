class CreateApiSessions < Sequel::Migration
  def up
    create_table :api_sessions do
      primary_key :id
      foreign_key :authed_user_id, :authed_users, :key => :id, :on_delete => :cascade, :null => false
      char :token, :size => 40, :null => false
      datetime :created_at, :null => false
      datetime :last_login, :null => false
    end
    
    add_index :api_sessions, :token
  end
  
  def down
    drop_table :api_sessions
  end
end