class RecipeShare < Sequel::Model(:recipe_shares)
  many_to_one :recipe
  updates_date_fields
end