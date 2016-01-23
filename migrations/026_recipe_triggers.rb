class RecipeTriggers < Sequel::Migration
  def up
    # This needs to run in the console
    %Q{
      delimiter |
      
      create trigger recipe_tags_trigger_ins after insert on recipe_tags
        for each row begin
          update recipes
          set updated_at = now()
          where id = new.recipe_id;
        end;
      |
      
      create trigger recipe_tags_trigger_del after delete on recipe_tags
        for each row begin
          update recipes
          set updated_at = now()
          where id = old.recipe_id;
        end;
      |
      
      create trigger ingredients_trigger_ins after insert on ingredients
        for each row begin
          update recipes
          set updated_at = now()
          where id = (
            select recipe_id as id
            from ingredient_groups
            where id = new.ingredient_group_id);
        end;
      |
      
      create trigger ingredients_trigger_up after update on ingredients
        for each row begin
          update recipes
          set updated_at = now()
          where id = (
            select recipe_id as id
            from ingredient_groups
            where id = new.ingredient_group_id);
        end;
      |
      
      create trigger ingredients_trigger_del after delete on ingredients
        for each row begin
          update recipes
          set updated_at = now()
          where id = (
            select recipe_id as id
            from ingredient_groups
            where id = old.ingredient_group_id);
        end;
      |
    }
  end
end