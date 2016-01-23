class UniqueFinders < Sequel::Migration
  def up
    DB << 'delete from category_finders where expression="turkey"'
    DB << 'delete from category_finders where expression="sugar"'
    
    alter_table :categories do
      add_index :name, :unique => true
    end
    
    alter_table :category_finders do
      add_index :expression, :unique => true
    end
    
    CategoryFinder.create(
      :expression => 'turkey',
      :category_id => Category[:name => 'Meat'].id)
    
    CategoryFinder.create(
      :expression => 'sugar',
      :category_id => Category[:name => 'Baking'].id)
  end
end