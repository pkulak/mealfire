class ShopController < Controller
  helper 'formatting'
  map '/shop'
  
  layout do |path, wish|
    if path == 'show'
      'simple'
    elsif !request.xhr?
      'default'
    end
  end
    
  def index
    @title = "Extra Items"
    @items = get_items
    show_banner
  end
  
  def change_category
    current_user.change_category(
      request[:food],
      request[:expression],
      Category[request[:category_id]]);
    
    "OK"
  end
  
  def email
    return "" unless current_user.authed?
    
    cats = JSON.parse(request[:text])
    message = ""

    cats.each do |cat|
      message << cat['name'] << "\n"
      
      cat['ingredients'].each do |i|
        i = Ingredient.from_si(i['si'] ? i['si'].to_f : nil, Unit.from_abbr(i['unit']), i['food'])
        message << "    " << ingredient_to_html(i, :ceiling => true) << "\n"
      end
      
      message << "\n"
    end
    
    send_mail(to: request[:email], subject: "Today's Shopping List", text_body: message)
  end
  
  def delete_ingredient
    saved_list = SavedList[request[:list_id]]
    return "Error" unless saved_list.user == current_user
    SavedFood.create(name: request[:food], saved_list_id: saved_list.id)
    "OK"
  end
  
  def undelete_ingredient
    saved_list = SavedList[request[:list_id]]
    return "Error" unless saved_list.user == current_user
    SavedFood[name: request[:food], saved_list_id: saved_list.id].destroy
    "OK"
  end
  
  def delete(id)
    sl = SavedList[user_id: current_user.id, id: id].required
    sl.destroy
    redirect "/calendar"
  end
  
  def add_items
    request[:text].required
    
    request[:text].strip.split("\n").each do |line|
      ShoppingListItem.create(:user_id => current_user.id, :text => line)
    end
    
    render_view(:_item_list, :items => get_items)
  end
  
  def remove_item
    ShoppingListItem[request[:id]].required.delete
    render_view(:_item_list, :items => get_items)
  end
  
  def remove_all
    ShoppingListItem.filter(:user_id => current_user.id).delete
    "success"
  end
  
  def edit_item
    item = ShoppingListItem[request[:id]].required
    item.text = request[:text] if !request[:text].blank?
    item.save
    render_view(:_item_list, :items => get_items)
  end
  
  def show
    ingredients = []
    
    if request[:days]
      @days = request[:days].split(',').collect do |d|
        Date.civil(*d.split('_').collect(&:to_i))
      end
      
      ingredients = RecipeDay.ingredients_for_days(@days, current_user)
      @saved_list = SavedList.new(user_id: current_user.id, days: @days)
      
      if request[:store_id]
        @saved_list.store_id = request[:store_id]
      end
      
      @saved_list.save
    elsif request[:recipe]
      @recipe = Recipe[:id => request[:recipe], :user_id => current_user.id].required
      ingredients = @recipe.ingredients
      ingredients.each{|i| i.source = [@recipe.name]}
    elsif request[:saved_list]
      @saved_list = SavedList[id: request[:saved_list], user_id: current_user.id].required
      ingredients = RecipeDay.ingredients_for_days(@saved_list.days, current_user)
      @days = @saved_list.days
    end
    
    if @saved_list
      @store = @saved_list.store
    end
    
    ingredients = Ingredient.combine_all(
      ingredients.concat(
        ShoppingListItem.get_ingredients(current_user)))
    
    @saved_list.filter_ingredients(ingredients) if @saved_list
    @categories = Category.split(current_user.categorize_ingredients(ingredients, @store))
    @sources = Ingredient.unique_sources(ingredients)
  end
  
  def get_items
    return [] if current_user.virgin?
    
    ShoppingListItem
      .filter(:user_id => current_user.id)
      .order(:created_at)
  end
  private :get_items
end