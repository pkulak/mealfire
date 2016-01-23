class Ingredient < Sequel::Model(:ingredients)
  plugin :serialize
  plugin :json
  
  attr_accessor :deleted, :source, :category_finder
  many_to_one :unit
  many_to_one :ingredient_group
  
  # Serialization
  attr :food
  attr :quantity
  association_attr :unit
  
  # This is set from the API controller.
  attr_accessor :string
  
  def initialize(*params)
    # We require a food in the DB, but it's okay if it never get's saved, so
    # we'll trick Sequel here.
    if params.is_a?(Array) && params[0].is_a?(Hash)
      if params[0].has_key?(:food) && params[0][:food] == nil
        params[0].delete(:food)
      end
    end
    
    super(*params)
  end
  
  def to_s
    Ramaze::Helper::Mealfire.ingredient_to_html(self)
  end
  
  # Splits the ingredient into two parts only if it can avoid a complicated
  # fraction by doing so.
  def split
    return self unless self.quantity && unit
    fraction = MF::Math.number_to_fraction(self.quantity)
    
    # If there's a range, it's not exact, so we don't need to split it.
    return self if self.range

    # You can't have tablespoons in thirds.
    if self.unit.abbr == 'Tbsp' && fraction[2] == 3
      first = Ingredient.new(
        quantity: self.quantity.floor,
        unit: self.unit)
      
      second = Ingredient.new(
        quantity: (self.quantity - self.quantity.floor) * 3,
        unit: Unit.from_abbr('tsp'),
        food: self.food)
      
      return [first, second]
    end
    
    # Now, convert everything else by getting as close as we can with one
    # fraction, then trying to beat it by adding small amounts.
    fraction = MF::Math.number_to_fraction(self.quantity, floor: true)

    if self.unit.abbr == 'cp'
      old_quantity = MF::Math.fraction_to_float(fraction)
      best_pair = nil
      best_difference = 1
      
      additions = [
        [1, 'Tbsp'],
        [2, 'Tbsp'],
        [3, 'Tbsp'],
        [1, 'tsp'],
        [2, 'tsp']]
      
      additions.each do |add|
        add_ingredient = Ingredient.new(quantity: add[0], unit: Unit[add[1]])
        new_quantity = old_quantity + add_ingredient.convert_to(self.unit).quantity
        
        difference = self.quantity - new_quantity
        
        if difference > -0.005 && difference < best_difference
          best_difference = difference
          
          first = Ingredient.new(quantity: old_quantity, unit: self.unit)
          
          add_ingredient.food = self.food
          
          best_pair = [first, add_ingredient]
        end
      end
            
      if best_difference < self.quantity - old_quantity
        return best_pair
      end
    end
    
    return self
  end

  def recipe
    self.ingredient_group.recipe
  end

  def self.unique_sources(ingredients)
    sources = ingredients.collect(&:source).flatten.compact.uniq.sort
    
    def sources.indices_of(sources)
      indices = []
      
      sources.each do |source|
        self.each_index do |i|
          if self[i] == source
            indices << i + 1
          end
        end
      end
      
      indices
    end
    
    return sources
  end

  def category
    @category ||= Category.find_category(self)
  end
  
  # This is the destructive version of the overloaded multiply.
  def multiply!(multiplier)
    self.quantity = self.quantity ? self.quantity * multiplier : nil
    
    unless multiplier == 1
      normalize!
    end
  end
  
  # NOT destructive, you get a brand new ingredient.
  def *(multiplier)
    i = Ingredient.new(
      :quantity => self.quantity ? self.quantity * multiplier : nil,
      :unit => self.unit,
      :food => self.food,
      :source => self.source)
    
    unless multiplier == 1
      i = Ingredient.normalize(i)
    end
    
    return i
  end
  
  def self.normalize(i, destructive = false)
    coverted = false
    
    while i.quantity && i.unit && i.unit.lower_bound && i.quantity <= i.unit.lower_bound
      if destructive
        i.convert_to!(i.unit.lower_unit)
      else
        i = i.convert_to(i.unit.lower_unit)
      end
      
      converted = true
    end
    
    unless converted
      while i.quantity && i.unit && i.unit.upper_bound && i.quantity >= i.unit.upper_bound
        if destructive
          i.convert_to!(i.unit.upper_unit)
        else
          i = i.convert_to(i.unit.upper_unit)
        end
      end
    end
    
    return i
  end
  
  def normalize!
    Ingredient.normalize(self, true)
  end
  
  def convert_to(other_unit)    
    i = Ingredient.new(
      :quantity => (self.quantity * self.unit.si) / other_unit.si,
      :unit => other_unit,
      :source => self.source)
    
    # Get around the not-nil requirement.
    i.food = self.food if self.food
    
    if self.range
      i.range = (self.range * self.unit.si) / other_user.si
    end
    
    return i
  end
  
  def convert_to!(other_unit)
    # I have to set this before I assign it... no idea why.
    new_quantity = (self.quantity * self.unit.si) / other_unit.si
    new_range = nil
    
    if self.range
      new_range = (self.range * self.unit.si) / other_unit.si
    end
    
    self.unit = other_unit
    self.quantity = new_quantity
    self.range = range
  end
  
  def /(divisor)
    self * (1.0 / divisor)
  end
  
  def self.from_si(si, unit, food)    
    if si && unit
      quantity = si.to_f / unit.si.to_f
    elsif si
      quantity = si
    else
      quantity = nil
    end
    
    Ingredient.new(:quantity => quantity, :unit => unit, :food => food)
  end
  
  def full?
    unit && quantity
  end
  
  def si
    if full?
      quantity * unit.si
    else
      nil
    end
  end

  def self.combine_all(ingredients)
    results = []
    
    ingredients.each do |i|
      comb = nil
      comb_index = nil
      
      results.each_index do |r_index|
        result = results[r_index].combine_with(i)
        
        if result.length == 1
          comb = result.first
          comb_index = r_index
        end
      end
      
      if comb
        results[comb_index] = comb
      else
        results << i
      end
    end
    
    return results
  end

  def combine_with(rhs)
    default = [self, rhs]

    if new_food = Ingredient.food_equality(rhs.food, self.food)
      # Sanity check
      rhs.quantity = 1 if !rhs.quantity && rhs.unit
      self.quantity = 1 if !self.quantity && self.unit
      
      if rhs.unit == self.unit
        q = rhs.quantity || self.quantity
        
        if rhs.quantity != nil && self.quantity != nil
          q = rhs.quantity + self.quantity
        end
      
        i = Ingredient.new(
          :quantity => q,
          :unit => self.unit,
          :food => new_food,
          :source => [self.source, rhs.source].flatten.compact)
        
        if self.range || rhs.range
          i.range = (self.range || self.quantity) + (rhs.range || rhs.quantity)
        end
        
        return [Ingredient.normalize(i)]
      else
        # Make sure we are dealing with the same dimension.
        if rhs.unit && self.unit && rhs.unit.type == self.unit.type
          # The larger unit is the one we'll use.
          final_unit = rhs.unit.si > self.unit.si ? rhs.unit : self.unit
          
          quantity =
            ((rhs.unit.si * rhs.quantity) + (self.unit.si * self.quantity)) /
            final_unit.si
          
          if self.range || rhs.range
            range =
              ((rhs.unit.si * (rhs.range || rhs.quantity)) +
              (self.unit.si * (self.range || self.quantity))) /
              final_unit.si
          else
            range = nil
          end

          i = Ingredient.new(
            :quantity => quantity,
            :range => range,
            :unit => final_unit,
            :food => new_food,
            :source => [self.source, rhs.source].flatten.compact)
          
          return [Ingredient.normalize(i)]
        else
          return default
        end
      end
    else
      return default
    end
  end
  
  def self.food_equality(l, r)
    r = r.downcase.strip
    l = l.downcase.strip
    
    if r == l
      return r
    elsif (r + 's') == l
      return l
    elsif r == (l + 's')
      return r
    else
      return false
    end
  end

  def self.parse(string)
    if string.blank?
      return nil
    end
    
    # Convert fractions from HTML and UTF to plain text.
    MF::Math::ALL_FRACTIONS.each do |f|
      unless f[2] == '1'
        sub = nil
        
        if string.include?(f[2])
          sub = f[2]
        elsif string.include?(f[3])
          sub = f[3]
        elsif string.include?(f[4])
          sub = f[4]
        end
        
        if sub
          string.gsub!(sub, " #{f[0].to_i}/#{f[1].to_i}")
        end
      end
    end
            
    # Do some cleanup.
    string.sub!(/^[^a-zA-Z0-9.#]*/, '')
    
    # Check for things like: 1 tbsp and 1 tsp
    if string =~ /\band\b|\bplus\b/
      head, tail = string.split(/\band\b|\bplus\b/, 2).collect{|s| parse(s)}
      
      if head && tail && head.quantity && head.unit && head.food.blank? &&
          tail.quantity && tail.unit && !tail.food.blank?
        head.food = tail.food
        return head.combine_with(tail)[0]
      end
    end
    
    # Check for ranges
    if string.include?(' to ') || string.include?('-')
      head, tail = string.split(/-| to /, 2).collect{|s| parse(s)}
      
      if head && tail && head.quantity && !head.unit && head.food.blank? &&
          tail.quantity && !tail.food.blank? && head.quantity < tail.quantity
        tail.quantity, tail.range = head.quantity, tail.quantity
        return tail
      end
    end
    
    quantity, string = parse_quantity(string)
    unit, string = parse_unit(string)
    food = parse_food(string)
    
    i = Ingredient.new(
      :quantity => quantity,
      :unit_id => unit ? unit.id : nil,
      :food => food)
          
    return i
  end
  
  def self.parse_food(string)
    string.sub(/^ *of/, '').strip
  end
  
  def self.parse_unit(string)
    # Trim some crap off the front.
    string.gsub!(/of +a */i, '')
    
    unit = nil
    split = nil
    
    Unit.cached_all.each do |u|      
      if split = string.index(Regexp.new("#{u.name}([^a-zA-Z]|s|S|$)")) 
        if split == 0
          unit = u
          split = u.name.length
        end
      else
        u.abbreviations.each do |abbr|
          if split = string.index(Regexp.new("#{abbr}([^a-zA-Z]|$)"))
            if split == 0
              unit = u
              split = abbr.length
              break
            end
          end
        end
      end
      
      break if unit
    end
    
    if unit
      # Chomp off some extra crap.
      if string[split, 1].downcase == 's'
        split += 1
      elsif string[split, 3].downcase == '(s)'
        split += 3
      elsif string[split, 1].downcase == '.'
        split += 1
      end

      return [unit, string[split..-1]]
    else
      return [nil, string]
    end
  end
  
  def self.parse_quantity(string)
    # Only deal with the part of the string that could be the quantity. This
    # will keep us from picking numbers in the name of the food.
    s = string.scan(/^([0-9 \/\.]+(and)*[0-9 \/\.]*)/)
    
    if s.length == 0
      return [nil, string]
    else
      s = s[0][0]
    end
    
    decimal = nil
    fraction = nil
    split = 0
    
    # Check for a fraction
    matches = s.scan(/\d+ *\/ *\d+/)
    
    if matches.length > 0
      fraction = matches[0]
      split = s.index(fraction) + fraction.length
    end
    
    # Find a decimal number.
    matches = (fraction ? s.sub(fraction, '') : s).scan(/\.*\d+\.*\d*/)
    
    if matches.length > 0
      decimal = matches[0]
      split = [split, s.index(decimal) + decimal.length].max
    end
        
    if decimal || fraction
      number = 0
      number += decimal.to_f if decimal
      
      if fraction
        num_den = fraction.split('/')
        number += num_den[0].to_f / num_den[1].to_f
      end
    else
      number = nil
    end
    
    return [number, string[split..-1].strip]
  end
  
  def before_create
    return false if super == false
    self.created_at = Time.now
  end
  
  def before_save
    if ingredient_group && self.order_by == nil
      self.order_by = ingredient_group.max_ingredient_order + 1
    end
    
    self.updated_at = Time.now
  end
end