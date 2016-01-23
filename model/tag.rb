class Tag < Sequel::Model(:tags)
  plugin :serialize
  plugin :json
  
  attr :name, :default => true, :include => true
  
  def self.add_data
    Tag.create(:name => 'breakfast')
    Tag.create(:name => 'lunch')
    Tag.create(:name => 'dinner')
    Tag.create(:name => 'snack')
    Tag.create(:name => 'dessert')
    Tag.create(:name => 'side dish')
    Tag.create(:name => 'appetizer')
  end
  
  def self.get_tag(name)
    name = Tag.sanitize(name)
    
    if name == 'top rated'
      raise UserException.new("That tag is not allowed.")
    end
    
    tag = Tag[:name => name]
    
    if !tag
      tag = Tag.create(:name => name)
    end
    
    return tag
  end
  
  def self.sanitize(name)
    name.downcase.gsub(/[^0-9a-z ]/, '').strip
  end
  
  def self.global_tags
    @@global_tags ||= Tag.filter{|t| t.id <= 7}.to_a
  end
  
  def total
    if self[:total]
      return self[:total]
    else
      raise 'The "total" attribute has not been set for this model.'
    end
  end
  
  def total=(rhs)
    self[:total] = rhs
  end
  
  def self.user_tags(user, sort = :name)
    query = Tag.select('tags.*, count(*) as total'.lit)
      .inner_join(:recipe_tags, :tag_id => :id)
      .inner_join(:recipes, :id => :recipe_id)
      .filter('recipes.user_id = ?', user.id)
      .group('1'.lit)
      
    if sort == :name
      query = query.order('tags.name'.lit)
    else
      query = query.reverse_order('total'.lit)
    end
      
    query.all
  end
  
  def self.sort_tags(tags, user_tags)
    tags.each do |tag|
      tag.total = user_tags.select{|t| t.id == tag.id}.first.total
    end
    
    tags.sort{|rhs, lhs| lhs.total <=> rhs.total}
  end
end