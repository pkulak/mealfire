class AddTimezones < Sequel::Migration
  def up
    add_column :authed_users, :timezone, :varchar
  end
  
  def down
    drop_column :authed_users, :timezone
  end
end