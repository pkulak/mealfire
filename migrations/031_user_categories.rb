class LoweredEmails < Sequel::Migration
  # ALTER TABLE `category_finders` ADD COLUMN `user_id` integer;
  # ALTER TABLE `categories` ADD COLUMN `user_id` integer;
  # alter table category_finders add foreign key fk_category_finders_users (user_id) references users (id) on delete cascade;
  # alter table categories add foreign key fk_categories_users (user_id) references users (id) on delete cascade;
  # alter table category_finders drop index category_finders_expression_index;
  # CREATE UNIQUE INDEX `category_finders_user_id_expression_index` ON `category_finders` (`user_id`, `expression`);
  # UPDATE `schema_info` SET `version` = 31;
  
  def up
    add_column :category_finders, :user_id, :integer
    add_column :categories, :user_id, :integer
    
    DB << "alter table category_finders add foreign key fk_category_finders_users (user_id) references users (id) on delete cascade"
    DB << "alter table categories add foreign key fk_categories_users (user_id) references users (id) on delete cascade"
    DB << "alter table category_finders drop index category_finders_expression_index"
    
    add_index :category_finders, [:user_id, :expression], :unique => true
  end
  
  def down
    drop_column :category_finders, :user_id
    drop_column :categories, :user_id
  end
end