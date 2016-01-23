class CategoryFinder < Sequel::Model(:category_finders)
  many_to_one :category
  attr_accessor :priority_bias
  @@all_categories = nil
  @@last_category_update = nil
  
  def self.cached_all(bust_cache = false)
    if bust_cache || !@@all_categories || @@last_category_update < 5.minutes.ago
      @@all_categories = self.filter('user_id is null').to_a
      @@last_category_update = Time.now
    end
    
    @@all_categories
  end
  
  def matches_food(food)
    food = food.downcase.gsub(/[^a-z ]/, '')
    
    if expression.include?('#')
      regex, p = expression.split('#')      
      return food =~ Regexp.new(regex)
    else
      singular = expression
      plural = make_plural(expression)
      
      return food.include?(singular) || food.include?(plural)
    end
  end
  
  def priority
    @priority ||= begin
      if expression.include?('#')
        expression.split('#')[1].split('=')[1].to_i
      else
        expression.length
      end
    end
    
    @priority + (@priority_bias || 0)
  end
  
  def make_plural(s)
    if s =~ /s$/
      return s
    end
    
    if s =~ /y$/
      return s[0...-1] + 'ies'
    end
    
    return s + 's'
  end
end