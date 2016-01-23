class Unicode < Sequel::Migration
  def up
    tables = %w{
      authed_users         
      categories           
      category_finders     
      ingredient_groups    
      ingredients          
      ip_logs              
      password_resets      
      recipe_days          
      recipe_shares        
      recipe_tags          
      recipe_texts         
      recipes              
      saved_foods          
      saved_lists          
      schema_info          
      shopping_list_items  
      tags                 
      units                
      users}
    
    tables.each do |table|
      DB << "alter table #{table} character set = utf8;"
    end
    
    DB << "alter database mealfire character set = utf8;"
    
    DB << 'alter table authed_users modify column `name` varchar(255) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table authed_users modify column `email` varchar(255) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table authed_users modify column `password` varchar(40) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table authed_users modify column `salt` varchar(5) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table authed_users modify column `transaction_id` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    DB << 'alter table authed_users modify column `timezone` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table categories modify column `name` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table category_finders modify column `expression` varchar(255) CHARACTER SET utf8 NOT NULL'
    
    DB << 'alter table ingredient_groups modify column `name` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table ingredients modify column `food` varchar(255) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table ingredients modify column `description` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table password_resets modify column `rand` char(10) CHARACTER SET utf8 NOT NULL'
    
    DB << 'alter table recipe_shares modify column `rand` varchar(20) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table recipe_shares modify column `email` varchar(255) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table recipe_shares modify column `message` varchar(1024) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table recipe_texts modify column `data` text CHARACTER SET utf8'
    
    DB << 'alter table recipes modify column `name` varchar(255) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table recipes modify column `directions` text CHARACTER SET utf8'
    DB << 'alter table recipes modify column `imported_from` varchar(1024) CHARACTER SET utf8 DEFAULT NULL'
    DB << 'alter table recipes modify column `image_hash` varchar(40) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table saved_foods modify column `name` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table saved_lists modify column `days` varchar(1024) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table shopping_list_items modify column `text` varchar(255) CHARACTER SET utf8 DEFAULT NULL'
    
    DB << 'alter table tags modify column `name` varchar(255) CHARACTER SET utf8 NOT NULL'
    
    DB << 'alter table units modify column `name` varchar(255) CHARACTER SET utf8 NOT NULL'
    DB << 'alter table units modify column `name` varchar(255) CHARACTER SET utf8 NOT NULL'
  end
end