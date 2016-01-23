class ApiSessionCreatedBy < Sequel::Migration
  # ALTER TABLE `api_sessions` ADD COLUMN `created_by` varchar(255);
  # CREATE INDEX `api_sessions_created_by_index` ON `api_sessions` (`created_by`);
  # UPDATE `schema_info` SET `version` = 33;
  
  def up
    add_column :api_sessions, :created_by, :varchar
    add_index :api_sessions, :created_by
  end
  
  def down
    drop_column :api_sessions, :created_by
  end
end