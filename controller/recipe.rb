class RecipeController < Controller
  map '/recipe'
  
  layout do |path, wish|
    if path == 'print' || path == 'cook'
      'simple'
    elsif !request.xhr?
      'default'
    end
  end
  
  def _tag_list(id)
    get_recipe(id)
  end
  
  def _ingredient_list(id)
    get_recipe(id)
  end
  
  def _buttons(id)
    get_recipe(id)
  end
  
  def _directions(id)
    get_recipe(id)
  end
  
  def index
    show_banner
    
    # Don't go to the DB is there's nothing there.
    if current_user.virgin?
      @recipes = MF::EmptyPaginator.new
      @user_tags = []
      return
    end
    
    if request[:q].blank?
      @recipes = current_user.recipes_dataset.eager(:recipe_tags => :tag)
        
      if !request[:tag].blank?   
        @recipes = @recipes
          .join(:recipe_tags, :recipe_id => :id)
          .join(:tags, :id => :tag_id)
          .filter('tags.name = ?', request[:tag])
          .select{:recipes.*}
      end
    
      if request[:top]
        @recipes = @recipes
          .filter('recipes.rating is not null')
          .order(:rating.desc)
      else
        @recipes = @recipes.reverse_order('recipes.id'.lit)
      end
    
      @total = @recipes.count
      
      @recipes = MF::Paginator.new(
        dataset: @recipes, 
        current_page: current_page, 
        per_page: 20)
    else
      @recipes, @total = MF::Solr.user_recipes(request[:q], current_user, 
        rows: 20,
        start: (current_page - 1) * 20)
      
      @recipes = MF::Paginator.new(
        records: @recipes,
        total: @total,
        current_page: current_page,
        per_page: 20)
    end
    
    @user_tags = Tag.user_tags(current_user)
    
    @title = "Your"
    @title << " Top-Rated" if request[:top]
    @title << "," if request[:top] && request[:tag]
    @title << " " + request[:tag].titleize if request[:tag]
    @title << " Recipes"
    
    @autocomplete_tags = Tag.user_tags(current_user)
      .to_a
      .concat(Tag.global_tags)
      .collect{|t| "'" + t.name + "'"}
      .uniq
      .join(',')
  end
  
  def cook
    @recipes = []
    
    request[:ids].split(',').each do |pair|
      id, multiplier = pair.split(':')
      recipe = Recipe[id]
      recipe.multiplier = multiplier.to_f
      @recipes << recipe
    end
        
    @recipes.each do |recipe|
      if recipe.user != current_user
        # TODO: Forward to the login screen.
        raise UserException.new("Please login to view that recipe.")
      end
    end
    
    @width = 100 / @recipes.length
    
    @make_link = Proc.new do |recipe, multiplier|
      parts = []
      
      @recipes.each do |r|
        if r == recipe
          parts << "#{r.id}:#{multiplier}"
        else
          parts << "#{r.id}:#{r.multiplier}"
        end
      end
      
      '/recipe/cook/' + parts.join(',')
    end
  end
  
  def schedule
    required_params :date
    get_recipe(request[:id])
    parts = request[:date].split('/')
    day = Date.civil(parts[2].to_i, parts[0].to_i, parts[1].to_i)
    Recipe.add_to_day(@recipe, day)
    "success"
  end
  
  def login_to_save
    if session[:login_to_save_id] && current_user.authed?
      recipe = Recipe[session[:login_to_save_id]]
      recipe.user_id = current_user.id
      recipe.save
      session[:login_to_save_id] = nil
      redirect "/recipe/edit/#{recipe.id}"
    else
      return "" if !request[:id]
      session[:login_to_save_id] = request[:id]
      session[:next] = '/recipe/login_to_save'
      redirect '/login'
    end
  end
  
  def begin
    @title = 'Create Recipe'
    show_banner
    @title = "New Recipe"
    return unless request.post?
    
    if request[:title].blank?
      flash.previous[:error] = "Please enter a title for your recipe."
      return
    end
    
    recipe = Recipe.create(
      :name => request[:title],
      :user_id => current_user.id)
      
    redirect "recipe/edit/#{recipe.id}"
  end
  
  def delete
    get_recipe(request[:id])
    @recipe.deleted = true
    @recipe.save
    flash[:notice] = ["Recipe Deleted", %Q{"#{h @recipe.name}" has been deleted.}]
  end
  
  def hide
    get_recipe(request[:id])
    @recipe.hidden = true
    @recipe.save
    respond "OK"
  end
  
  def unhide
    get_recipe(request[:id])
    @recipe.hidden = false
    @recipe.save
    respond "OK"
  end
  
  def make_public
    get_recipe(request[:id])
    @recipe.is_public = true
    @recipe.save
    respond "OK"
  end
  
  def make_private
    get_recipe(request[:id])
    @recipe.is_public = false
    @recipe.save
    respond "OK"
  end
  
  def edit
    id = request[:id]
    show_banner
    
    if id =~ /^day/
      return redirect "/recipe/#{RecipeDay[id.split('_')[1]].recipe_id}"
    end
    
    @recipe ||= Recipe[id].required

    if @recipe.user != current_user
      @recipe.must_be_public_and_original
      return redirect "/recipe/view/#{@recipe.multi_id}"
    end
     
    @title = "Recipe - #{@recipe.name}"
    
    @multiplier = request[:multiplier] ? request[:multiplier].to_f : 1
    
    @autocomplete_tags = Tag.user_tags(current_user)
      .to_a
      .concat(Tag.global_tags)
      .reject{|t| @recipe.tags.include?(t)}
      .collect{|t| "'" + t.name + "'"}
      .uniq
      .join(',')
  end
  
  def print
    id = request[:id]
    
    if id.blank?
      nil.required
    end
    
    # If it's a share
    if id.length == 20
      @recipe = RecipeShare[rand: id].required.recipe
    elsif id =~ /^rcp/
      @recipe = Recipe[id: id_from_multi(id)]
    elsif id =~ /^day/
      url = "/recipe/print/#{RecipeDay[id_from_multi(id)].recipe_id}"
      
      if request[:multiplier]
        url += "?multiplier=#{request[:multiplier]}"
      end
      
      return redirect(url)
    end
    
    get_recipe(id)
    
    # Multiply if needed.
    if request[:multiplier]
      @recipe.multiply!(request[:multiplier].to_f)
      
      @friendly_multiplier =
        if request[:multiplier].to_f == 0.5
          "Half Recipe"
        elsif request[:multiplier].to_f == 2
          "Double Recipe"
        else
          "x #{h request[:multiplier]}"
        end
    end
    
    @title = "#{@recipe.name}"
  end
  
  def share(id)
    must_be_authed(raise_exception: true)
    get_recipe(id)
    
    if request[:email].blank?
      return flash[:notice] = ["Email Required", "You must enter an email address."]
    end
    
    @recipe.email_share(current_user.authed_user, request[:email], request[:message])
    
    return 'success'
  end
  
  def get_share_url
    get_recipe(request[:id])
    
    share = RecipeShare.create(
      recipe_id: @recipe.id,
      recipient: request[:recipient],
      rand: MF::Math.random_string(20))
    
    return "http://mealfire.com/r/#{share.rand}"
  end
  
  def view(rand)
    if rand.length == 20
      share = RecipeShare[rand: rand].required
    
      if !share.viewed_at
        share.viewed_at = Time.now
      end
      
      share.hit_count += 1
      share.save
      
      @rand = share.rand
      @recipe = share.recipe
    elsif rand =~ /^rcp/
      @recipe = Recipe[id: id_from_multi(rand)].required.must_be_public_and_original
      @rand = @recipe.multi_id
    else
      raise UserException.new("Invalid URL")
    end
    
    @multiplier = (request[:multiplier] || 1).to_f
    @title = @recipe.name + " Recipe"
  end
  
  def add_share(rand)    
    if rand.length == 20
      share = RecipeShare[rand: rand].required
      new_recipe = share.recipe.duplicate(current_user)
    elsif rand =~ /^rcp/
      new_recipe = Recipe[id: id_from_multi(rand)]
        .required
        .must_be_public_and_original
        .duplicate(current_user)
    end
    
    flash[:notice] = ["Recipe Added", "The recipe has been added to your collection."]
    redirect "/recipe/edit/#{new_recipe.id}"
  end
  
  def login_to_collect_share(rand)
    session[:next] = "/recipe/add_share/#{rand}"
    redirect "/login"
  end
  
  def edit_title(id)    
    get_recipe(id)
    
    if request.post?
      @recipe.name = request[:title]
      @recipe.save
      return @recipe.name
    else
      return %Q{
        <input id="recipe_edit_box" type="text" value="#{h @recipe.name}"/>
      }
    end
  end
  
  def add_ingredients(id)
    get_recipe(id)
    
    if request.post?
      request['text'].force_encoding('UTF-8')
      @recipe.add_ingredients(request[:text], IngredientGroup[request[:group_id]])
      return render_partial("_ingredient_list/#{@recipe.id}")
    else
      return %Q{
        <p style="margin-top:0;">Type your ingredients below, one per line.</p>
        <textarea id="ingredients_input"></textarea>
      }
    end
  end
  
  def edit_ingredient(id)
    get_ingredient(id)
    
    if request.post?
      if !request[:text].blank?
        new_ingredient = Ingredient.parse(request[:text])

        @ingredient.update(
          :quantity => new_ingredient.quantity,
          :range => new_ingredient.range,
          :unit_id => new_ingredient.unit_id,
          :food => new_ingredient.food)
      end
            
      return render_partial("_ingredient_list/#{@ingredient.recipe.id}")
    else
      return %Q{
        <input id="ingredient_edit_box" type="text" value="#{ingredient_to_html(@ingredient, :html_fraction => false)}"/>
      }
    end
  end
  
  def promote_ingredient
    get_ingredient(request[:id])
    Recipe.promote_ingredient(@ingredient)
    return render_partial("_ingredient_list/#{@ingredient.recipe.id}")
  end
  
  def demote_group
    get_ingredient_group(request[:id])
    Recipe.demote_group(@group)
    return render_partial("_ingredient_list/#{@group.recipe.id}")
  end
  
  def delete_ingredient(id)
    get_ingredient(id)
    @ingredient.destroy
    ""
  end
  
  def move_ingredient
    get_ingredient(request[:ingredient_id])
    new_group = IngredientGroup[request[:new_group_id]]
    previous = Ingredient[request[:previous_id]]
    Recipe.change_ingredient_order(@ingredient, new_group, previous)
    ""
  end
  
  def move_group
    get_ingredient_group(request[:group_id])
    previous = IngredientGroup[request[:previous_id]]
    Recipe.change_ingredient_group_order(@group, previous)
    ""
  end
  
  def add_ingredient_group(id)
    get_recipe(id)
    
    if request.post?
      @recipe.add_ingredient_group(name: request[:text])
      return render_partial("_ingredient_list/#{@recipe.id}")
    else
      return %Q{
        <input type="text" id="ingredient_group_input"/>
      }
    end
  end
  
  def edit_ingredient_group(id)
    get_ingredient_group(id)
    
    if request.post?
      @group.update(:name => request[:text])
      return render_partial("_ingredient_list/#{@group.recipe_id}")
    else
      return %Q{
        <input id="ingredient_group_edit_box" type="text" value="#{h @group.name}"/>
      }
    end
  end
  
  def delete_ingredient_group(id)
    get_ingredient_group(id)
    @group.destroy
    ""
  end
  
  def add_image(id)
    if request.post?
      get_recipe(id)
      
      if !request[:file]
        flash[:notice] = ["No File", "Please select a file to upload."]
        redirect "/recipe/edit/#{id}"
      end
      
      file = request[:file][:tempfile]
      @recipe.set_image(open(file.path, "rb") {|io| io.read})
      redirect "recipe/edit/#{id}"
    else
      return %Q{<input type="file" name="file" />}
    end
  end
  
  def remove_image(id)
    get_recipe(id)
    @recipe.remove_image
    render_partial('_buttons')
  end
  
  def edit_directions(id)
    get_recipe(id)
    
    if request.post?
      @recipe.directions = request[:text]
      @recipe.save
      render_partial("_directions/#{@recipe.id}")
    else
      %Q{
        <div class="yui-skin-sam">
          <textarea id="directions_input">#{h @recipe.directions}</textarea>
        </div>
      }
    end
  end
  
  def add_tag(id)
    get_recipe(id)
    tag = @recipe.add_tag(request[:name])
    
    if request[:render_tag_only]
      respond tag.name
    else
      render_partial("_tag_list/#{@recipe.id}")
    end
  rescue UserException => e
    respond e.message, 400
  end
  
  def delete_tag(id)
    get_recipe_tag(id)
    @recipe_tag.destroy
    render_partial("_tag_list/#{@recipe_tag.recipe.id}")
  end
  
  def get_recipe(id)
    return unless !@recipe
    
    @recipe = Recipe[id].required
    
    if @recipe.user.id != current_user.id
      raise UserException.new("That is not your recipe.")
    end
  end
  private :get_recipe
  
  def get_ingredient(id)
    @ingredient = Ingredient[id].required
    
    if @ingredient.ingredient_group.recipe.user != current_user
      raise UserException.new("That is not your recipe.")
    end
  end
  private :get_ingredient
  
  def get_ingredient_group(id)
    @group = IngredientGroup[id].required
    
    if @group.recipe.user != current_user
      raise UserException.new("That is not your recipe.")
    end
  end
  private :get_ingredient_group
  
  def get_recipe_tag(id)
    @recipe_tag = RecipeTag[id].required
    
    if @recipe_tag.recipe.user != current_user
      raise UserException.new("That is not your recipe.")
    end
  end
  private :get_recipe_tag
end