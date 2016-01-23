class Recipe < Sequel::Model(:recipes)
  plugin :serialize
  plugin :json
  
  attr_accessor :multiplier
  many_to_one :user
  one_to_many :recipe_tags, :order => :id, :eager => :tag
  many_to_many :tags, :join_table => :recipe_tags
  one_to_many :ingredient_groups, :order => :order_by
  one_to_many :recipe_shares
  one_to_many :ratings
  updates_date_fields
    
  # Serialization
  attr :name, :default => true, :order => true, :include => true
  attr :id, :default => true, :include => true
  attr :directions
  attr :created_at, :order => true, :default => true
  attr :updated_at
  attr :imported_from
  attr :last_served_at
  attr :hidden
  attr :rating, :order => true, :default => true
  
  attr :image_thumb,  :columns => [:image_hash]
  attr :image_small,  :columns => [:image_hash]
  attr :image_medium, :columns => [:image_hash]
  attr :image_large,  :columns => [:image_hash]
  
  association_attr :tags
  association_attr :ingredient_groups
  
  def self.maximum_limit
    1000
  end
  
  def shares
    return @shares if @shares
    
    # I need a deep clone.
    recipe_shares = RecipeShare.where(recipe_id: self.id).all
    
    @shares = []
    
    recipe_shares.clone.each do |s|
      # Don't show the Facebook hit
      if s.recipient == "Facebook"
        s.hit_count = [0, s.hit_count - 1].max
      end
      
      @shares << s
    end
    
    @shares
  end
  
  def add_rating(value)
    return unless self.user.authed?
    
    if !self.rating
      self.rating = 0.5
    end
    
    self.rating += (value - self.rating) / 5
    
    if !self.user.max_rating || self.rating > self.user.max_rating
      self.user.authed_user.max_rating = self.rating
      self.user.authed_user.save
    end
    
    if !self.user.min_rating || self.rating < self.user.min_rating
      self.user.authed_user.min_rating = self.rating
      self.user.authed_user.save
    end
    
    self.save
  end
  
  def normalized_rating(min, max)
    return nil if !self.rating
    return 0.5 if !min || !max || (min == max)
    
    (self.rating - min) / (max - min)
  end
  
  def public_url
    if !self.is_imported
      '/recipe/view/' + multi_id
    else
      self.imported_from
    end
  end
  
  def multi_id
    "rcp_" + self.id.to_s
  end
  
  def self.add_to_day(recipe, day)
    unless RecipeDay[:day => day, :recipe_id => recipe.id]
      RecipeDay.create(
        :day => day,
        :recipe_id => recipe.id,
        :user_id => recipe.user.id,
        :order_by => Recipe.max_day_order(day, recipe.user) + 1)
    end
  end
  
  def is_imported
    self.imported_from != nil
  end
  
  def must_be_original
    if self.is_imported
      raise ImportedRecipeViewException.new(self)
    end
    
    self
  end
  
  def must_be_public
    if !self.is_public
      raise PrivateRecipeViewException.new(self)
    end
    
    self
  end
  
  def must_be_public_and_original
    self.must_be_public.must_be_original
  end
  
  def self.recently_collected
    Recipe
      .filter('imported_from is not null and image_hash is not null')
      .reverse_order(:id)
      .limit(12)
      .all
  end
  
  def multiply!(multiplier)
    ingredients.each do |i|
      i.multiply!(multiplier)
    end
  end
  
  def email_share(authed_user, to_email, message)
    share = RecipeShare.create(
      recipe_id: self.id,
      rand: MF::Math.random_string(20),
      recipient: to_email)
    
    if message.blank?
      message = "#{authed_user.name} has shared a recipe with you on Mealfire!"
    end
    
    message <<
      "\n\nClick on the link below (or copy and paste it into your browser) " +
      "to view this recipe or add it to your collection.\n\n" +
      "http://#{DOMAIN}/r/#{share.rand}"
      
    MF::Mailer.send_mail(
      to: to_email,
      reply_to: authed_user,
      subject: "#{authed_user.name} has shared a Mealfire recipe with you...",
      text_body: message)
  end
  
  def duplicate(new_user)
    recipe = Recipe.create(
      name: self.name,
      user_id: new_user.id,
      image_hash: self.image_hash,
      directions: self.directions)
     
   # Copy the ingredients.
   self.ingredient_groups.each do |grp|
     new_group = IngredientGroup.create(
       name: grp.name,
       recipe_id: recipe.id,
       order_by: grp.order_by)
    
     grp.ingredients.each do |i|
       Ingredient.create(
         quantity: i.quantity,
         unit_id: i.unit_id,
         food: i.food,
         order_by: i.order_by,
         ingredient_group_id: new_group.id)
     end
   end
   
   # Copy the tags.
   self.recipe_tags.each do |rt|
    RecipeTag.create(
      recipe_id: recipe.id,
      tag_id: rt.tag_id)
   end
   
   return recipe
  end
  
  def ingredients
    ingredients = []
    
    ingredient_groups.each do |ig|
      ingredients << ig.ingredients
    end
    
    ingredients.flatten
  end
  
  def tags
    self.recipe_tags.collect(&:tag)
  end
  
  def self.max_day_order(day, user)
    max_order = DB[%Q{
      select max(order_by) as max_order
      from recipe_days
      where day = ? and user_id = ?}, day, user.id]
    
    return max_order.first[:max_order] || 0
  end
  
  def add_tag(name)
    tag = Tag.get_tag(name)
    
    if !RecipeTag[:recipe_id => self.id, :tag_id => tag.id] && !name.blank?
      RecipeTag.create(:recipe_id => self.id, :tag_id => tag.id)
    end
    
    tag
  end
  
  def directions=(rhs)
    self[:directions] = MF::Sanitizer.sanitize(rhs)
  end
  
  def has_image
    self.image_hash != nil
  end
  
  def set_image(data)
    self.image_hash = MF::S3.get_hash(data)
    
    if !Recipe[image_hash: self.image_hash]
      MF::S3.upload_versions(data, self.image_hash)
    end
    
    self.save
  end
  
  # Removes the _reference_ to the image. It's still on S3 until
  # it's overwritten.
  def remove_image
    self.image_hash = nil
    self.save
  end
  
  # A strict version of image_url
  def image(size)
    if self.has_image
      image_url(size)
    else
      nil
    end
  end
  
  def image_thumb; image(:thumb); end
  def image_small; image(:small); end
  def image_medium; image(:medium); end
  def image_large; image(:large); end
  
  def image_url(size = :medium)    
    if size == :thumb
      if self.has_image
        "http://static.mealfire.com/#{self.image_hash}_48.jpeg"
      else
        "/images/no_image/48.png"
      end
    elsif size == :small
      "http://static.mealfire.com/#{self.image_hash}_100.jpeg"
    elsif size == :medium
      "http://static.mealfire.com/#{self.image_hash}_250.jpeg"
    elsif size == :large
      "http://static.mealfire.com/#{self.image_hash}_640.jpeg"
    else
      raise "Please supply either :thumb, :small, :medium, or :large."
    end
  end
  
  def max_ingredient_group_order
    max_order = DB[%Q{
      select max(order_by) as max_order
      from ingredient_groups
      where recipe_id = #{self.id}}]
    
    return max_order.first[:max_order] || 0
  end
  
  def min_ingredient_group_order
    min_order = DB[%Q{
      select min(order_by) as min_order
      from ingredient_groups
      where recipe_id = #{self.id}}]
    
    return min_order.first[:min_order] || 0
  end
  
  def add_ingredients(list, group = nil)    
    if !group
      if self.ingredient_groups.length == 0
        group = add_ingredient_group(name: nil, order_by: 1)
      else
        group = self.ingredient_groups.last
      end
    else
      if !group.recipe == self
        raise "Invalid ingredient group."
      end
    end
    
    ingredients = list.is_a?(Array) ? list : list.strip.split("\n")
    
    ingredients.each do |line|
      ingredient = Ingredient.parse(line);
      group.add_ingredient(ingredient) if ingredient
    end
  end
  
  def self.change_ingredient_order(ingredient, new_group, after)
    if after && ingredient.ingredient_group.recipe != after.ingredient_group.recipe
      raise "Both ingredients must be from the same recipe."
    end
    
    if ingredient.ingredient_group.recipe != new_group.recipe
      raise "You cannot move a recipe between groups."
    end
    
    ingredient.ingredient_group = new_group
    
    if !after
      ingredient.order_by = new_group.min_ingredient_order - 1
      ingredient.save
      return ingredient
    end
    
    # Bump everything after our new ingredient up by one.
    DB << %Q{
      update ingredients
      set order_by = order_by + 1
      where ingredient_group_id = #{new_group.id}
        and order_by > #{after.order_by}
    }
    
    # And now out our ingredient after... after.
    ingredient.order_by = after.order_by + 1
    ingredient.save
    return ingredient
  end
  
  def self.change_ingredient_group_order(group, after)
    if after && group.recipe != after.recipe
      raise "You cannot move a group between two recipes."
    end
    
    if !after
      group.order_by = group.recipe.min_ingredient_group_order - 1
      group.save
      return group
    end
    
    DB << %Q{
      update ingredient_groups
      set order_by = order_by + 1
      where recipe_id = #{group.recipe.id}
        and order_by > #{after.order_by}
    }
    
    group.order_by = after.order_by + 1
    group.save
    return group
  end
  
  # Makes an ingredient an ingredient group
  def self.promote_ingredient(ingredient)
    new_group = ingredient.recipe.add_ingredient_group(name: ingredient.food)
    
    # Move all the ingredients after the promoted ingredient to the new group.
    DB << %Q{
      update ingredients
      set ingredient_group_id = #{new_group.id}
      where ingredient_group_id = #{ingredient.ingredient_group_id}
        and order_by > #{ingredient.order_by}
    }
    
    # Move the new group after the ingredient's parent.
    DB << %Q{
      update ingredient_groups
      set order_by = order_by + 1
      where recipe_id = #{ingredient.recipe.id}
        and order_by > #{ingredient.ingredient_group.order_by}
    }
    
    new_group.order_by = ingredient.ingredient_group.order_by + 1
    new_group.save
    
    ingredient.destroy
  end
  
  # Changes a recipe group into an ingredient.
  def self.demote_group(group)
    # Find the group just before this one.
    previous_group = nil
    
    group.recipe.ingredient_groups.each do |g|
      break if group == g
      previous_group = g
    end

    new_ingredient = Ingredient.parse(group.name)
    
    if previous_group
      new_order_by = group.max_ingredient_order
      
      [new_ingredient, group.ingredients].flatten.compact.each do |i|
        new_order_by += 1
        i.ingredient_group = previous_group
        i.order_by = new_order_by
        i.save
      end
      
      group.destroy
    elsif new_ingredient
      new_ingredient.order_by = group.min_ingredient_order - 1
      new_ingredient.ingredient_group_id = group.id
      group.name = nil
      new_ingredient.save
      group.save
    end

    group.recipe.refresh
    group.recipe.defrag
  end
  
  # Combines adjancent groups with no titles and removes empty groups.
  def defrag
    if self.ingredient_groups.length < 2
      return
    end
    
    previous = self.ingredient_groups[0]
    
    self.ingredient_groups[1..-1].each do |current|
      if previous.name.blank? && current.name.blank?
        max_order_by = previous.max_ingredient_order
        
        # Take the current's ingredients and move them up.
        current.ingredients.each do |i|
          i.ingredient_group_id = previous.id
          i.order_by += max_order_by
          i.save
        end
        
        # Get rid of the now-empty group.
        current.destroy
      end
      
      previous = current
    end
  end
end
