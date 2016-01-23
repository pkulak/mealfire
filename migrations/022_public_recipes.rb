class PublicRecipes < Sequel::Migration
  def up
    add_column :recipes, :is_public, :boolean, default: true, null: false
    
    Recipe.columns
    
    # Set all original recipes to private.
    Recipe.all.each do |r|
      if !r.is_imported
        r.is_public = false
        r.save
      end
    end
  end
  
  def down
    drop_column :recipes, :is_public
  end
end