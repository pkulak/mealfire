class IndexSalt < Sequel::Migration
  def up
    add_index :authed_users, :salt, :unique => true
  end
end