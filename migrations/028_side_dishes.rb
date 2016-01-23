class SideDishes < Sequel::Migration
  def up
    add_column :recipes, :side_dish, :boolean, null: false, default: false
    add_index :recipes, :side_dish
    
    %Q{
      delimiter |
      
      drop trigger recipe_days_trigger_del|
      
      create trigger recipe_days_trigger_del after delete on recipe_days
        for each row begin
          update recipes
          set last_served_at = (
            select max(day)
            from recipe_days
            where user_id = recipes.user_id
              and recipe_id = recipes.id)
          where id = old.recipe_id;
          
          delete from recipes
          where id = old.recipe_id and side_dish = 1;
        end;
      |
    }
  end
  
  def down
    drop_column :recipes, :side_dish
  end
end