class LoweredEmails < Sequel::Migration
  def up
    add_column :authed_users, :lowered_email, :varchar
    add_index :authed_users, :lowered_email, unique: true
    execute "update authed_users set lowered_email = lower(email)"
    
    %Q{
      delimiter |
      
      create trigger authed_users_trigger_ins before insert on authed_users
        for each row begin
          set new.lowered_email = lower(new.email);
        end;
      |
      
      create trigger authed_users_trigger_up before update on authed_users
        for each row begin
          set new.lowered_email = lower(new.email);
        end;
      |
    }
  end
  
  def down
    drop_column :authed_users, :lowered_email
  end
end