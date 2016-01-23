class IngredientDescription < Sequel::Migration
  def up
    add_column :ingredients, :description, :varchar
  end
end