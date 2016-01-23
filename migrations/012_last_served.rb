class LastServed < Sequel::Migration
  def up
    add_column :recipes, :last_served_at, :date
    
    DB << %Q{
      update recipes
      set last_served_at = (
        select max(day)
        from recipe_days
        where user_id = recipes.user_id
          and recipe_id = recipes.id)
    }
    
    # This needs to be run in the console. Maybe it could be put in a
    # migration, but I just don't feel like going through the hassel.
    %Q{
      delimiter |
      
      create trigger recipe_days_trigger_ins after insert on recipe_days
        for each row begin
          update recipes
          set last_served_at = (
            select max(day)
            from recipe_days
            where user_id = recipes.user_id
              and recipe_id = recipes.id)
          where id = new.recipe_id;
        end;
      |
      
      create trigger recipe_days_trigger_up after update on recipe_days
        for each row begin
          update recipes
          set last_served_at = (
            select max(day)
            from recipe_days
            where user_id = recipes.user_id
              and recipe_id = recipes.id)
          where id in (new.recipe_id, old.recipe_id);
        end;
      |
      
      create trigger recipe_days_trigger_del after delete on recipe_days
        for each row begin
          update recipes
          set last_served_at = (
            select max(day)
            from recipe_days
            where user_id = recipes.user_id
              and recipe_id = recipes.id)
          where id = old.recipe_id;
        end;
      |
    }
  end
  
  def down
    drop_column :recipes, :last_served_at
  end
end