class RecipeDay < Sequel::Model(:recipe_days)
  plugin :serialize
  plugin :json
  
  many_to_one :user
  many_to_one :recipe
  
  attr :id, :default => true
  attr :day, :default => true
  association_attr :recipe, :default => true
  
  def rate(value)
    r = Rating.create(recipe_day_id: self.id, recipe_id: self.recipe.id, value: value)
    self.is_rated = true
    self.save
    self.recipe.add_rating(value)
    r
  end
  
  def self.ingredients_for_days(days, user)
    ingredients = DB.fetch(%q{
      select i.*, rd.multiplier, r.name recipe_name
      from ingredients i
        inner join ingredient_groups ig on i.ingredient_group_id = ig.id
        inner join recipe_days rd on rd.recipe_id = ig.recipe_id
        inner join recipes r on r.id = ig.recipe_id
      where day in ? and r.user_id = ?
    }, days, user.id)
        
    ingredients.collect do |i|
      new_i = Ingredient.new(
        :quantity => i[:quantity],
        :unit_id => i[:unit_id],
        :food => i[:food].force_encoding('UTF-8'),
        :source => [i[:recipe_name].force_encoding('UTF-8')])
            
      new_i * i[:multiplier]
    end
  end
  
  def self.get_span(user, first_day, last_day)
    RecipeDay.filter(
      'user_id = ? and day >= ? and day <= ?',
      user.id, first_day, last_day)
      .eager(:recipe).all
  end
  
  def self.all_for_day(user, day)
    RecipeDay.filter('user_id = ? and day = ?', user.id, day)
    .eager(:recipe).to_a
  end
end