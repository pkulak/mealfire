class CalendarController < Controller
  map '/calendar'
  
  def _recipe
    id = request[:id].required
    
    type, id = id.split('_')
    
    if type == 'day'
      @recipe_day = RecipeDay[id].required
      @recipe = @recipe_day.recipe
    else
      @recipe = Recipe[id].required
    end
    
    return "" unless @recipe.user == current_user
  end
  
  def _month
    required_params :year, :month
    
    @month = MF::Month.new(request[:year].to_i, request[:month].to_i, self)
    @month.fill_days(
      RecipeDay.get_span(current_user, @month.first_day, @month.last_day),
      SavedList.get_span(current_user, @month.first_day, @month.last_day))
  end
  
  def _recipes
    if current_user.virgin?
      respond [].to_json
    end
      
    if !request[:id].blank?
      @recipes = current_user.recipes_dataset
        .inner_join(:recipe_tags, :recipe_id => :id)
        .filter(tag_id: request[:id], hidden: false)
        .select(:recipes.*)
    else
      @recipes = current_user.recipes_dataset.filter(hidden: false)
    end
    
    if request[:include_tags]
      @recipes = @recipes.eager(:recipe_tags => :tag)
    end
    
    if request[:order] == 'last_served'
      @recipes = @recipes.order(:last_served_at, :name)
    else
      @recipes = @recipes.order(:name)
    end
    
    if request[:include_tags]
      data = @recipes.all.collect do |r|
        {i: r.id, n: r.name, t: r.recipe_tags.collect{|rt| rt.tag.name}}
      end
    else
      data = @recipes.collect{|r| {i: r.id, n: r.name}}
    end
    
    respond data.to_json
  end
  
  def _shopping_list
    days = request[:days].split(',').collect do |d|
      Date.civil(*d.split('_').collect(&:to_i))
    end
    
    @ingredients = Ingredient.combine_all(
      RecipeDay.ingredients_for_days(days, current_user))
  end
  
  def index
    @title = 'Calendar'
    
    @month = MF::Month.new(Date.today.year, Date.today.month, self)
    
    if !current_user.virgin?
      @month.fill_days(
        RecipeDay.get_span(current_user, @month.first_day, @month.last_day),
        SavedList.get_span(current_user, @month.first_day, @month.last_day))
      
      @recipe_count = current_user.recipes_dataset.filter(hidden: false).count
      @tags = Tag.user_tags(current_user)
    else
      @recipe_count = 0
      @tags = []
    end

    show_banner
  end
  
  def export
    user = AuthedUser[salt: request[:salt]].required.user
    respond(user.get_ical)
  end
  
  def create_ingredient
    required_params :si, :unit, :food
    
    ingredient = Ingredient.from_si(
      request[:si].to_i,
      Unit.from_abbr(request[:unit]),
      request[:food])
    
    respond ingredient_to_html(ingredient,
      :html_fraction => true,
      :ceiling => true)
  end
  
  def multiply_recipe_day
    @recipe_day = RecipeDay[request[:id]].required
    @recipe_day.multiplier = request[:multiplier].to_f
    @recipe_day.save
    
    render_view(:_recipe, :recipe_day => @recipe_day, :recipe => @recipe_day.recipe)
  end
  
  def move_recipe
    day = RecipeDay[request[:day_id]].required
    
    if day.recipe.user != current_user
      return "That's not your recipe!"
    end
    
    new_day = Date.civil(request[:year].to_i, request[:month].to_i, request[:day].to_i)
    old_day = day.day
    
    # Don't do anything if there's not actually a move.
    unless new_day == old_day
      # If we're moving it onto a day that would dupe it.
      if RecipeDay[:day => new_day, :recipe_id => day.recipe.id, :user_id => current_user.id]
        day.destroy
      else
        day.day = new_day
        day.order_by = Recipe.max_day_order(new_day, current_user) + 1
        day.save
      end
    end
    
    # Render the two days that have been modified.
    @month = MF::Month.new(request[:current_year].to_i, request[:current_month].to_i, self)
    
    @month.fill_days(
      RecipeDay.all_for_day(current_user, new_day).concat(
      RecipeDay.all_for_day(current_user, old_day)).uniq,
      SavedList.all_for_day(current_user, new_day).concat(
      SavedList.all_for_day(current_user, old_day)).uniq)
        
    respond({
      :old_day => @month.render_day(old_day),
      :new_day => @month.render_day(new_day)
    }.to_json)
  end
  
  def remove_recipe
    day = RecipeDay[request[:id]].required
    
    if day.recipe.user != current_user
      return "That's not your recipe!"
    end
    
    day.destroy
    render_day(day.day)
  end
  
  def add_recipe
    required_params :year, :month, :day
    
    day = Date.civil(request[:year].to_i, request[:month].to_i, request[:day].to_i)
    recipe = Recipe[request[:recipe_id]].required
    
    if recipe.user != current_user
      return "That's not your recipe!"
    end
    
    Recipe.add_to_day(recipe, day)

    return render_day(day)
  end
  
  def add_side_dish
    required_params :year, :month, :day
    day = Date.civil(request[:year].to_i, request[:month].to_i, request[:day].to_i)
    
    recipe = Recipe.create(
      name: request[:title] || "Side Dish",
      user_id: current_user.id,
      directions: request[:notes].gsub("\n", '<br>'),
      side_dish: true)
    
    recipe.add_ingredients(request[:ingredients])
    Recipe.add_to_day(recipe, day)
    
    return render_day(day)
  end
  
  def render_day(day)
    month = MF::Month.new(request[:current_year].to_i, request[:current_month].to_i, self)
    month.fill_days(
      RecipeDay.all_for_day(current_user, day),
      SavedList.all_for_day(current_user, day))
    month.render_day(day)
  end
  private :render_day
end