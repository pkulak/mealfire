class SavedList < Sequel::Model(:saved_lists)
  plugin :serialize
  plugin :json
  
  one_to_many :saved_foods
  many_to_one :store
  many_to_one :user
  updates_date_fields
  
  # Serialization
  attr :id, :default => true
  attr :created_at, :default => true, :order => true
    
  # Marks all ingredients "deleted" that appear in this list.
  def filter_ingredients(ingredients)
    foods = self.saved_foods.collect(&:name)
    
    ingredients.each do |i|
      if foods.include?(i.food)
        i.deleted = true
      end
    end
    
    ingredients
  end

  def days=(value)
    self[:days] = YAML::dump(value)
  end
  
  def days
    YAML::load(self[:days])
  end
  
  def day(user)
    adjusted = user.adjust_time(created_at)
    Date.new(adjusted.year, adjusted.month, adjusted.day)
  end
  
  def self.get_span(user, first_day, last_day)
    SavedList.filter(
      'user_id = ? and ((created_at + interval ? second) between ? and ?)',
      user.id, user.tz_offset, first_day, last_day + 1).all
  end
  
  def self.all_for_day(user, day)
    SavedList.filter('user_id = ? and date(created_at + interval ? second) = ?',
      user.id, user.tz_offset, day).all
  end
end