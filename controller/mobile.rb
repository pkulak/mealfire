class MobileController < Controller
  layout('mobile'){|path, wish| !request.xhr?}
  
  def login
    return unless request.post?
    
    begin
      login_user(User.authenticate(request[:email], request[:password]))
    rescue UserException => e
      respond e.message
    end
    
    respond 'success'
  end
  
  def login_check
    if current_user.authed?
      respond "1"
    else
      respond "0"
    end
  end
  
  def get_shopping_list_items
    respond ShoppingListItem
      .filter(:user_id => current_user.id)
      .order(:id)
      .collect{|s| [s.id, s.text]}
      .to_json
  end
  
  def get_saved_lists
    lists = SavedList
      .filter(:user_id => current_user.id)
      .reverse_order(:id)
      .limit(10)
    
    lists = lists.collect do |l|
      [l.id, current_user.adjust_time(l.created_at).strftime('%a %b %e, %Y')]
    end
    
    respond lists.to_json
  end
  
  def delete_item(id)
    item = ShoppingListItem[id]
    return '' unless item.user_id == current_user.id
    item.destroy
    respond 'success'
  end
  
  def add_item
    if request[:text].blank?
      respond 'error:Please enter the name of your item.'
    end
    
    item = ShoppingListItem.create(:user_id => current_user.id, :text => request[:text])
    respond item.id
  end
  
  def all_recipes
    respond Recipe
      .filter(:user_id => current_user.id)
      .order(:name)
      .collect{|r| [r.id, r.name]}
      .to_json
  end
  
  def get_recipe(id)
    @recipe = Recipe[id].required
  end
  
  def get_saved_list(id)
    list = SavedList[id: id, user_id: current_user.id].required
    ingredients = RecipeDay.ingredients_for_days(list.days, current_user)
    list.filter_ingredients(ingredients)
    ingredients.reject!{|i| i.deleted}
    
    ingredients = Ingredient.combine_all(
      ingredients.concat(
        ShoppingListItem.get_ingredients(current_user)))
    
    categories = current_user.categorize_ingredients(ingredients, list.store)
    
    cats_hash = categories.collect do |c|
      children = c.children.collect do |i|
        ingredient_to_html(i, :html_fraction => true, :ceiling => true)
      end
      
      {name: c.name, children: children}
    end
    
    respond cats_hash.to_json
  end
end