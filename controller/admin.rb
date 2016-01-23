class AdminController < Controller
  map '/admin'
  
  def categories
    if request.post?
      CategoryFinder.create(
        :category_id => request[:category],
        :expression => request[:expression].downcase)
    end
    
    # Bust the cache for the admin page.
    CategoryFinder.cached_all(true)
    
    @last_ingredients = Ingredient.reverse_order(:id)
    @last_ingredients = MF::Paginator.new(
      dataset: @last_ingredients,
      current_page: current_page,
      per_page: 15)
    
    last_items = ShoppingListItem.reverse_order(:id)
    last_items = MF::Paginator.new(
      dataset: last_items,
      current_page: current_page,
      per_page: 5)
    
    @last_ingredients.concat(last_items.to_a).collect! do |i|
      if i.is_a?(Ingredient)
        i
      else
        ret = Ingredient.parse(i.text)
        ret.created_at = i.created_at
        ret
      end
    end
    
    @categories = current_user.categorize_ingredients(@last_ingredients)
  end
  
  def errors
    @errors = MF::Paginator.new(
      dataset: ErrorLog.where(invalid: false, completed: false).reverse_order(:id),
      current_page: current_page,
      per_page: 50)
  end
  
  def view_error
    @error = ErrorLog[request[:id]]
  end
  
  def invalid_error
    @error = ErrorLog[request[:id]]
    @error.invalid = true
    @error.save
    redirect '/admin/errors'
  end
  
  def completed_error
    @error = ErrorLog[request[:id]]
    @error.completed = true
    @error.save
    redirect '/admin/errors'
  end
  
  before_all do
    redirect_referrer unless current_user.admin?
  end
end