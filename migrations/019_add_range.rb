class AddRange < Sequel::Migration
  def up
    add_column :ingredients, :range, :float
  end
  
  def down
    drop_column :ingredients, :range
  end
end