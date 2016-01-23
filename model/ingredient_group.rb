class IngredientGroup < Sequel::Model(:ingredient_groups)
  plugin :serialize
  plugin :json
  
  many_to_one :recipe
  one_to_many :ingredients, :order => :order_by
  
  attr :id, default: true
  attr :name, default: true, include: true
  attr :sub_group, default: true, include: true
  association_attr :ingredients
  
  def sub_group
    !name.blank?
  end
  
  def max_ingredient_order
    max_order = DB[%Q{
      select max(order_by) as max_order
      from ingredients
      where ingredient_group_id = #{self.id}}]
    
    return max_order.first[:max_order] || 0
  end
  
  def min_ingredient_order
    min_order = DB[%Q{
      select min(order_by) as min_order
      from ingredients
      where ingredient_group_id = #{self.id}}]
    
    return min_order.first[:min_order] || 0
  end

  def before_create
    return false if super == false
    self.created_at = Time.now
  end
  
  def before_save    
    if recipe && self.order_by == nil
      self.order_by = recipe.max_ingredient_group_order + 1
    end
    
    self.updated_at = Time.now
  end
end