class ShoppingListItem < Sequel::Model(:shopping_list_items)
  many_to_one :user
  updates_date_fields
  
  def self.get_ingredients(user)
    items = ShoppingListItem.filter(:user_id => user.id)
    
    items.collect do |item|
      i = Ingredient.parse(item.text)
      i.id = item.id
      i.source = ["Extra Items"]
      i
    end
  end
end