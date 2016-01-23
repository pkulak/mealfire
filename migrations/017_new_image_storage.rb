class NewImageStorage < Sequel::Migration
  def up
    add_column :recipes, :image_hash, :varchar, :size => 40
    add_index :recipes, :image_hash
    Recipe.columns
    
    Recipe.filter("image_uploaded_at is not null").each do |recipe|
      recipe.image_hash = "recipe:#{recipe.id}"
      recipe.save
    end
  end
end