class RecipeTag < Sequel::Model(:recipe_tags)
  many_to_one :tag
  many_to_one :recipe
end