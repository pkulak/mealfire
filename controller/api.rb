class ApiController < Controller
  layout nil
  
  def recipe_to_hash(r)
    @user_tags ||= Tag.user_tags(@user, :sort => :total)
    
    {name: r.name,
      id: r.id,
      tags: Tag.sort_tags(r.tags, @user_tags).collect(&:name),
      img: r.has_image ? r.image_url(:thumb) : nil}
  end
  private :recipe_to_hash
  
  def get_token    
    begin
      user = User.authenticate(request[:email], request[:password])
    rescue UserException => e
      return respond e.message, 400
    end
        
    session = ApiSession.create_for_user(user)
    respond session.token
  end
  
  def get_recipes
    recipes = @user.recipes_dataset
      .order(:name)
      .eager(:recipe_tags => :tag)
      .all
    
    respond recipes.collect{|r| recipe_to_hash(r)}.to_json
  end
  
  def get_recipe_html
    @recipe = @user.recipes_dataset
      .where(id: request[:id])
      .first
    
    respond "Not Found", 400 unless @recipe
    
    @next_day = RecipeDay
      .where(recipe_id: @recipe.id).where('day >= curdate()')
      .order(:day)
      .first

    if @next_day
      if @next_day.day == Date.today
        @next_day = "today"
      elsif @next_day.day == Date.today + 1
        @next_day = "tomorrow"
      else
        @next_day = @next_day.day.strftime('%a, %b %e')
      end
    end
  end
  
  def schedule_recipe
    day = Date.civil(request[:year].to_i, request[:month].to_i, request[:day].to_i)
    recipe = Recipe[request[:recipe_id]].required
    
    if recipe.user != @user
      respond '400', 400
    end
    
    Recipe.add_to_day(recipe, day)

    respond 'Success'
  end
  
  def get_extra_items
    respond ShoppingListItem
      .filter(user_id: @user.id)
      .order(:id)
      .collect{|s| {id: s.id, name: s.text}}
      .to_json
  end
  
  def delete_extra_item
    sli = ShoppingListItem[request[:id]]
    
    respond "Not Found", 400 unless sli && sli.user == @user
    
    sli.destroy
    respond "Success"
  end
  
  def add_extra_item
    respond "Failure" unless request[:name].length > 0
    sli = ShoppingListItem.create(user_id: @user.id, text: request[:name])
    respond sli.id
  end
  
  def get_lists
    respond SavedList
      .filter(user_id: @user.id)
      .limit(10)
      .order(:created_at.desc)
      .collect{|l| {id: l.id, name: format_date(@user.adjust_time(l.created_at), user: @user)}}
      .to_json
  end
  
  def get_list
    list = SavedList[id: request[:id], user_id: @user.id]
    ingredients = RecipeDay.ingredients_for_days(list.days, @user)
    list.filter_ingredients(ingredients)
    ingredients.reject!{|i| i.deleted}
    
    ingredients = Ingredient.combine_all(
      ingredients.concat(
        ShoppingListItem.get_ingredients(@user)))
    
    categories = @user.categorize_ingredients(ingredients, list.store)
    
    cats_hash = categories.collect do |c|
      children = c.children.collect do |i|
        ingredient_to_html(i, :html_fraction => false, :ceiling => true)
      end
      
      {name: c.name, children: children}
    end
    
    respond cats_hash.to_json
  end
  
  def get_stores
    respond Store
      .filter(user_id: @user.id)
      .order(:name)
      .collect{|s| {id: s.id, name: s.name}}
      .to_json
  end
  
  def get_store
    respond Store[id: request[:id], user_id: @user.id]
      .categories
      .collect{|c| {name: c.name, id: c.id}}
      .to_json
  end
  
  def update_store
    store = Store[id: request[:id], user_id: @user.id]
    store.categories = request[:categories]
    store.save
    respond "Success"
  end
  
  def get_calendar
    recipe_days = RecipeDay
      .filter(user_id: @user.id).filter("day >= curdate()")
      .eager(:recipe)
      .order(:day)
      .limit(20)
      .all
      
    days = []
    
    recipe_days.each do |rd|
      day_string = format_date(rd.day)
      
      if days.length == 0 || days.last[:day] != day_string
        days << {day: day_string, recipes: []}
      end
      
      days.last[:recipes] << recipe_to_hash(rd.recipe)
    end
    
    respond days.to_json
  end
  
  before :get_recipes, :get_recipe_html, :get_extra_items, :delete_extra_item,
      :add_extra_item, :get_lists, :get_list, :get_stores, :get_store,
      :update_store, :schedule_recipe, :get_calendar do

    session = ApiSession[token: request[:token]]
    
    if !session
      return respond "Invalid Token", 400
    end
    
    @authed_user = session.authed_user
    @user = @authed_user.user
  end
end