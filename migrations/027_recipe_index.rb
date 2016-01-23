class RecipeIndex < Sequel::Migration
  def up
    alter_table :recipes do
      add_index :updated_at
    end
  end
  
  def down
  end
end