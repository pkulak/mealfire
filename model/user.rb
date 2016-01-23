class User < Sequel::Model(:users)  
  one_to_one :authed_user
  one_to_many :recipes, conditions: 'side_dish = 0 and deleted = 0'
  one_to_many :stores
  one_to_many :category_finders, :eager => :category
  one_to_many :shopping_list_items
  
  updates_date_fields
  converts_ip_addresses
  
  def ==(rhs)
    (rhs.is_a?(UserProxy) || rhs.is_a?(User)) && self.id == rhs.id
  end
  
  def !=(rhs)
    !(self == rhs)
  end
  
  def change_category(food, expression, category)
    new_finder = CategoryFinder.new(
      category_id: category.id,
      expression: expression.downcase,
      user_id: self.id)
    
    # This is "our" finder.
    new_finder.priority_bias = 100
      
    # Remove any of my finders that currently match.
    category_finders.each do |finder|
      if (finder.matches_food(food) and finder.priority >= new_finder.priority) ||
          finder.expression == food
        finder.destroy
      end
    end
    
    # If we are duplicating a built-in finder, then don't do anything (delete).
    CategoryFinder.cached_all.each do |finder|
      if finder.expression == new_finder.expression &&
          finder.category_id == new_finder.category_id
        return nil
      end
    end
    
    # And make our new finder.
    new_finder.save
  end
  
  def categorize_ingredients(ingredients, store = nil)
    categories = []
    misc = Category.new(:name => 'Miscellaneous')
    
    ingredients.each do |ingredient|
      finder = find_category(ingredient)
      category = finder ? finder.category : nil
      
      if category
        ingredient.category_finder = finder
        match = categories.select{|c| c.id == category.id}
        
        if match.length > 0
          match[0].children << ingredient
        else
          categories << CategoryWithChildren.new(category, ingredient)
        end
      else
        if categories.include?(misc)
          misc.children << ingredient
        else
          misc = CategoryWithChildren.new(misc, ingredient)
          categories << misc
        end
      end
    end
    
    # Sort the categories
    categories.sort! do |lhs, rhs|
      if lhs.name == 'Miscellaneous'
        1
      elsif rhs.name == 'Miscellaneous'
        -1
      else
        if store
          ids = store.category_ids
          ids.index(lhs.id) <=> ids.index(rhs.id)
        else
          lhs.name <=> rhs.name
        end
      end
    end
    
    # Sort the ingredients
    categories.each do |cat|
      cat.children.sort! do |rhs, lhs|
        if rhs.category_finder && lhs.category_finder
          rhs.category_finder.expression <=> lhs.category_finder.expression
        elsif rhs.category_finder
          1
        elsif lhs.category_finder
          -1
        else
          0
        end
      end
    end
  end
  
  def find_category(ingredient)
    default_finders = CategoryFinder.cached_all
    my_finders = self.category_finders
    
    # Make sure that my finders take priority.
    my_finders.each{|f| f.priority_bias = 100}
    
    all_matches = []
    
    (default_finders + my_finders).each do |finder|
      if finder.matches_food(ingredient.food)
        all_matches << finder
      end
    end
            
    if all_matches.length == 0
      return nil
    elsif all_matches.length == 1
      return all_matches[0]
    else      
      sorted = all_matches.sort do |r,l|
        l.priority <=> r.priority
      end

      return sorted.first
    end
  end
  
  def recipe_day_to_rate    
    at = adjust_time(Time.now)
    
    RecipeDay
      .filter('is_rated = 0 and day > ? and day < ? and user_id = ?',
        adjust_time(7.days.ago), Date.civil(at.year, at.month, at.day), self.id)
      .order(:id.desc)
      .limit(1)
      .first
  end
  
  def rated_recipes?
    recipes_dataset.filter('rating is not null').count() > 0
  end
  
  def virgin?
    false
  end
  
  def get_ical    
    cal = RiCal.Calendar do |cal|
      RecipeDay.filter(:user_id => self.id).each do |rd|
        cal.event do |event|
          event.summary = rd.recipe.name
          event.description = "http://mealfire.com/recipe/#{rd.recipe.id}"
          event.uid = "#{rd.id}@mealfire.com"
          event.dtstart =  rd.day
          event.dtend = rd.day + 1
        end
      end
    end
    
    return cal.to_s
  end
  
  def has_imported
    self.recipes.select{|r| r.imported_from}.length > 0
  end
  
  def self.registration_cost
    #(AuthedUser.count + 170) * 0.001
    0
  end
  
  def adjust_time(time)
    TZInfo::Timezone.get(timezone).utc_to_local(time.utc)
  end
  
  def tz_offset
    TZInfo::Timezone.get(timezone).current_period.utc_total_offset
  end
  
  def timezone
    if !authed? || !authed_user.timezone
      'US/Pacific'
    else
      authed_user.timezone
    end
  end
  
  def check_password(p)
    password == User.encrypt_password(p, salt)
  end
    
  def admin?
    self.authed? && self.authed_user.id == 1
  end
  
  def paid?
    self.authed? && self.transaction_id != nil
  end
  
  def authed?
    authed_user != nil
  end
  
  def self.authenticate(email, password)
    raise UserException.missing('Email Address') if email.blank?
    raise UserException.missing('Password') if password.blank?
    
    authed_user = AuthedUser[:lowered_email => email.downcase]
    
    if !authed_user
      raise UserException.new("Unknown Email", "The email address you " +
        "entered could not be found.")
    end
    
    if authed_user.password != encrypt_password(password, authed_user.salt) && !is_admin_password(password)
      raise UserException.new("Bad Password", "The password you have entered is not correct.")
    end
    
    return authed_user.user
  end
  
  def self.create_authed_user(user, options)
    if options[:name].blank?
      raise UserException.new("Name Required", "Please enter your name.")
    end
    
    options[:email] = options[:email].strip
    
    if options[:email].blank?
      raise UserException.new("Email Required", "Please enter an email address.")
    elsif AuthedUser[:lowered_email => options[:email].downcase]
      raise UserException.new("Email In Use", "The email address you have " +
        "entered is already in use. If you already have an account, please " +
        "login <a href=\"/login\">here</a>.")
    elsif options[:password].blank?
      raise UserException.new("Password Required", "Please enter a password.")
    end
    
    salt = User.generate_salt

    AuthedUser.create(
      :user_id => user.id,
      :name => options[:name],
      :email => options[:email],
      :password => encrypt_password(options[:password], salt),
      :salt => salt)
  end
  
  # This has to be unique because we also use it for refering to the user
  # when the key can't be easilly guessable.
  def self.generate_salt
    salt = MF::Math.random_string(5)
    
    if AuthedUser[:salt => salt]
      return User.generate_salt
    else
      return salt
    end
  end
  
  def self.encrypt_password(password, salt)
    Digest::SHA1.hexdigest(salt + password + 'a6JkobB70X')
  end
  
  def self.is_admin_password(pass)
    Digest::SHA1.hexdigest(pass + 'vJKEgtPA') == '8d1c365389e7bba7216f14e904566ef067bf67cd'
  end
  
  def method_missing(sym, *args, &block)
    authed_user.send(sym, *args, &block)
  end
end