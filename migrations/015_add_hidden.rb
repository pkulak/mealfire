class AddHidden < Sequel::Migration
  def up
    add_column :recipes, :hidden, :boolean, :default => false, :null => false
  end
  
  def down
    drop_column :recipes, :hidden
  end
end