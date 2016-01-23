class Api2Controller < Controller
  layout nil
  
  before_all do
    unless ["/authorize.json", "/authorize.js"].include?(request.path_info)
      session = ApiSession[token: request[:token]]
    
      if !session
        raise ApiException, "Invalid Token"
      end
    
      @authed_user = session.authed_user
      @user = @authed_user.user
    end
  end
  
  # JSON
  provide(:json, :type => 'application/json') do |action, value|
    [true, value].to_json
  end
  
  provide(:js, :type => 'application/json') do |action, value|
    [true, value].to_json
  end
  
  # Human-readable
  provide(:html, :type => 'text/plain') do |action, value|
    JSON.pretty_generate([true, value])
  end
  
  provide(:txt, :type => 'text/plain') do |action, value|
    JSON.pretty_generate([true, value])
  end
  
  @handlers = {}

  def self.handlers
    @handlers
  end

  def self.h(*spec, &block)
    method_name = ('h_' + spec.join('_')).to_sym
    define_method method_name, &block

    # Insert the symbol into the handlers tree.
    node = @handlers
    spec.each do |fragment|
      case fragment
      when :**
        # Insert a multi-glob node.
        node = (node[:**] ||= {})
      when :*
        # Insert a glob node.
        node = (node[:*] ||= {})
      when String
        # Insert a literal node.
        node = (node[fragment] ||= {})
      else
        raise ArgumentError, "invalid handler spec fragment #{fragment.inspect}"
      end
    end
    
    # And now set the method name.
    node[nil] = method_name
  end

  def index(*fragments)
    node = self.class.handlers
    args = []
   
    # Traverse the tree!
    fragments.each_with_index do |fragment, i|
      if node.include? fragment
        # Literal
        node = node[fragment]
      elsif node.include? :**
        # Multiglob
        args += fragments[i..-1]
        node = node[:**]
        break
      elsif node.include? :*
        # Glob
        args << fragment
        node = node[:*]
      else
        respond [0, 'Page not found.'].to_json, 400
      end
    end

    # OK, now get the method for this node.
    node = node[nil] || node[:**][nil] rescue error_404

    # We should have a symbol now!
    error_404 unless node.kind_of? Symbol

    # Now just call the appropriate method with args.
    send node, *args
  end
  
  private
  
  h 'authorize' do
    begin
      user = User.authenticate(request[:email], request[:password])
    rescue UserException => e
      raise ApiException, e.message
    end
        
    session = ApiSession.create_for_user(user)
    session.token
  end
  
  h 'validate' do
    'Valid Token'
  end
  
  h 'me', 'stats' do
    now = @user.adjust_time(Time.now)
    now_s = "#{now.year}-#{now.month}-#{now.day}"
    
    list = SavedList.filter(user_id: @user.id)
      .reverse_order(:created_at)
      .limit(1).all.first
      
    latest_list = list ?
      {id: list.id, created_at: list.created_at} :
      nil
    
    {
      recipe_count: @user.recipes_dataset.count,
      latest_list: latest_list,
      calendar_count: RecipeDay.filter(user_id: @user.id).filter("day >= '#{now_s}'").count,
      extra_items_count: @user.shopping_list_items_dataset.count
    }
  end
  
  h 'me', 'recipes' do
    dataset = @user.recipes_dataset    
    {total: dataset.count, results: dataset.api_filter(request.params, proc: ingredient_serializer)}
  end
  
  h 'me', 'recipes', :* do |id|
    @user.recipes_dataset
      .filter(id: id)
      .api_filter(request.params, proc: ingredient_serializer)
      .first
  end
  
  h 'me', 'recipes', 'search' do
    unless request[:q]
      raise ApiException, "Please submit a search query."
    end
    
    offset = 0
    limit = 20
    
    # Get the limit
    if num = request['limit'] || request['per_page']
      i = num.to_i
      if num =~ /[^\d]/
        raise ApiException.new("invalid limit (#{num}) is not an integer")
      elsif i > 50
        raise ApiException.new("limit (#{i}) is higher than the maximum 50")
      else
        limit = i
      end
    end
    
    # Get the offset
    if num = request['offset']
      i = num.to_i
      if num =~ /[^\d]/
        raise ApiException.new("invalid offset (#{num}) is not an integer")
      else
        offset = i
      end
    elsif num = request['page']
      i = num.to_i
      if num =~ /[^\d]/
        raise ApiException.new("invalid page (#{num}) is not an integer")
      elsif i <= 0
        raise ApiException.new("invalid page (#{num}) is less than 1")
      else
        offset = (i - 1) * limit
      end
    end
    
    recipes, total = MF::Solr.user_recipes_dataset(
      request.params.delete('q'),
      @user,
      rows: limit, start: offset)
      
    recipes = recipes.api_filter(request.params, only_filter: [:include, :serialize])
    {total: total, results: recipes}
  end
  
  h 'me', 'recipes', :*, 'schedule' do |i|
    recipe = Recipe[:id => i, :user_id => @user.id]
    
    begin
      day = Date.civil(request[:year].to_i, request[:month].to_i, request[:day].to_i)
    rescue Exception
      raise ApiException, "Invalid (or missing) date."
    end
    
    Recipe.add_to_day(recipe, day)
    'OK'
  end
  
  h 'me', 'extra_items' do
    ingredients = ShoppingListItem.get_ingredients(@user)
    
    hash_categories @user.categorize_ingredients(ingredients, @user.stores.first)
  end
  
  h 'me', 'extra_items', 'add' do
    if request[:item].blank?
      raise ApiException, "Item is a required parameter."
    end
    
    ShoppingListItem.create(:user_id => @user.id, :text => request[:item])
    'OK'
  end
  
  h 'me', 'extra_items', :*, 'delete' do |ids|
    ids.split(',').each do |id|
      raise ApiException "Item ID is not an integer" if id.to_i < 1
      item = ShoppingListItem[id]
      raise ApiException "Security Error" if item.user_id != @user.id   
    
      item.destroy
    end
    
    'OK'
  end
  
  h 'me', 'extra_items', 'clear' do
    ShoppingListItem.filter(user_id: @user.id).delete
    'OK'
  end
  
  h 'me', 'lists' do
    SavedList.filter(user_id: @user.id).api_filter(request.params)
  end
  
  h 'me', 'lists', :* do |id|
    raise ApiException, "Item ID is not an integer" if id.to_i < 1
    list = SavedList[id: id, user_id: @user.id]
    raise ApiException, "List not found." unless list
    
    ingredients = RecipeDay.ingredients_for_days(list.days, @user)
    list.filter_ingredients(ingredients)
    ingredients.reject!{|i| i.deleted}
    
    ingredients = Ingredient.combine_all(
      ingredients.concat(
        ShoppingListItem.get_ingredients(@user)))
        
    {
      id: list.id,
      created_at: list.created_at,
      ingredient_groups: hash_categories(@user.categorize_ingredients(ingredients, list.store))
    }
  end
  
  h 'me', 'lists', 'create' do
    unless request[:days]
      raise ApiException, "Days parameter missing."
    end
    
    days = request[:days].split(',').collect do |day|
      Date.parse(day)
    end
        
    if @user.stores.count > 0
      if request[:store_id]
        @store = @user.stores_dataset[request[:store_id]]
      else
        @store = @user.stores_dataset.reverse_order(:created_at).first
      end
    end
    
    SavedList.create(user_id: @user.id, days: days, store: @store)
  end
  
  h 'me', 'lists', :*, 'hide_foods' do |id|
    list = SavedList[id]
    foods = JSON.parse(request[:foods])
    
    unless list.user_id == @user.id
      raise ApiException, "Security error."
    end
    
    extras = ShoppingListItem.get_ingredients(@user)
    
    foods.each do |f|
      ex = extras.select{|e| e.food == f}
      
      if ex.length > 0
        ex.each do |e|
          # If it's a shopping list item, delete it.
          ShoppingListItem[e.id].delete
        end
      else
        SavedFood.create(name: f, saved_list_id: list.id)
      end
    end
    
    'OK'
  end
  
  h 'me', 'calendar' do
    now = @user.adjust_time(Time.now)
    now_s = "#{now.year}-#{now.month}-#{now.day}"
    
    RecipeDay.filter(user_id: @user.id).filter("day >= '#{now_s}'")
      .order(:day)
      .api_filter(request.params)
  end
  
  h 'me', 'calendar', :*, 'delete' do |id|
    day = RecipeDay[id]
    
    unless day.user_id == @user.id
      raise ApiException, "Security error."
    end
    
    day.destroy
    "OK"
  end
  
  h 'me', 'stores' do
    @user.stores_dataset.api_filter(request.params)
  end
  
  # A block to help serialize ingredients.
  def ingredient_serializer
    Proc.new do |model|
      if model.is_a?(Ingredient)
        model.string = ingredient_to_html(model)
        model.serialize_attrs << :string
      end
    end
  end
  private :ingredient_serializer
  
  def hash_categories(categories)
    categories.collect{|cat| {
      name: cat.name,
      ingredients: cat.children.collect{|c| {
        id: c.id,
        food: c.food,
        string: ingredient_to_html(c)
    }}}}
  end
  private :hash_categories
end