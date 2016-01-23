class DeletedRecipes < Sequel::Migration
  # ALTER TABLE `recipes` ADD COLUMN `deleted` bool DEFAULT 0
  # CREATE INDEX `recipes_deleted_index` ON `recipes` (`deleted`)
  # UPDATE `schema_info` SET `version` = 32
  
  def up
    add_column :recipes, :deleted, :bool, :default => false
    add_index :recipes, :deleted
  end
  
  def down
    drop_column :recipes, :deleted
  end
end