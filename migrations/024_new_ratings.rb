class NewRatings < Sequel::Migration
  def up
    begin
      add_column :authed_users, :max_rating, :float
      add_column :authed_users, :min_rating, :float
    rescue Exception
      # Pass
    end
        
    DB << "update recipes set rating = null"
    
    Rating.all.each do |r|
      r.recipe.add_rating(r.value)
    end
  end
  
  def down
    drop_column :authed_users, :rating_window
  end
end