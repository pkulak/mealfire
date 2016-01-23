class InitialSchema < Sequel::Migration
  def up
    create_table :users do
      primary_key :id
      datetime :created_at, :null => false
    end
    
    DB << "alter table users add ip int(11) unsigned not null"

    create_table :authed_users do
      primary_key :id
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false, :unique => true
      varchar :name, :null => false
      varchar :email, :null => false, :unique => :true
      char :password, :null => false, :size => 40
      char :salt, :null => false, :size => 5
      varchar :transaction_id
      datetime :created_at, :null => false
    
      index :email
    end

    create_table :units do
      primary_key :id
      varchar :name, :null => false
      varchar :abbreviation, :null => false
      integer :type, :null => false
      float :si, :null => false
      float :lower_bound
      foreign_key :lower_unit_id, :units, :key => :id
      float :upper_bound
      foreign_key :upper_unit_id, :units, :key => :id
    end

    create_table :recipes do
      primary_key :id
      varchar :name, :null => false
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      varchar :directions, :size => 2048
      datetime :image_uploaded_at
      datetime :created_at, :null => false
      datetime :updated_at, :null => false
     end

    create_table :ingredient_groups do
      primary_key :id
      varchar :name
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      integer :order_by, :null => false
      datetime :created_at, :null => false
      datetime :updated_at, :null => false
     end

    create_table :ingredients do
      primary_key :id
      float :quantity
      varchar :food, :null => false
      foreign_key :unit_id, :units, :key => :id
      foreign_key :ingredient_group_id, :ingredient_groups, :key => :id, :on_delete => :cascade, :null => false
      integer :order_by, :null => false
      datetime :created_at, :null => false
      datetime :updated_at, :null => false
    end

    create_table :tags do
      primary_key :id
      varchar :name, :null => false
     
      index :name, :unique => true
    end

    create_table :recipe_tags do
      primary_key :id
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      foreign_key :tag_id, :tags, :key => :id, :null => false
      
      index [:recipe_id, :tag_id], :unique => true
    end
    
    create_table :recipe_days do
      primary_key :id
      date :day, :null => false
      foreign_key :recipe_id, :recipes, :key => :id, :on_delete => :cascade, :null => false
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      integer :order_by, :null => false
      float :multiplier, :null => false, :default => 1
      
      index :day
      index [:day, :recipe_id], :unique => true
      index [:day, :user_id, :order_by], :unique => true
    end
    
    create_table :ip_logs do
      primary_key :id
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      datetime :created_at, :null => false
      
      index :user_id
      index :created_at
    end
    
    DB << "alter table ip_logs add ip int(11) unsigned not null"
    
    alter_table :ip_logs do
      add_index :ip
      add_index [:ip, :user_id]
    end
    
    create_table :shopping_list_items do
      primary_key :id
      foreign_key :user_id, :users, :key => :id, :on_delete => :cascade, :null => false
      varchar :text
      datetime :created_at
      datetime :updated_at
      
      index :user_id
    end
     
    # Put in some data.
    Unit.columns
    Unit.add_data

    Tag.columns
    Tag.add_data
  end
  
  def down
    drop_table(:recipe_tags)
    drop_table(:recipe_days)
    drop_table(:shopping_list_items)
    drop_table(:ingredients)
    drop_table(:ingredient_groups)
    drop_table(:recipes)
    drop_table(:units)
    drop_table(:authed_users)
    drop_table(:ip_logs)
    drop_table(:users)
    drop_table(:tags)
  end
end