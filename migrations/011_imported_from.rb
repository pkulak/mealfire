class AddTimezones < Sequel::Migration
  def up
    add_column :recipes, :imported_from, :varchar, :size => 1024
  end
  
  def down
    drop_column :recipes, :imported_from
  end
end