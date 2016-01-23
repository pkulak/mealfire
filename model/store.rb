class Store < Sequel::Model(:stores)
  plugin :serialize
  plugin :json
  
  many_to_one :user
  updates_date_fields
  
  # Serialization
  attr :id, :default => true, :include => true
  attr :name, :default => true, :order => true, :include => true
  
  def categories
    Category.all.sort_by_ids(self.category_ids)
  end
  
  def category_ids
    self[:categories].split(',').collect{|i| i.to_i}
  end
end