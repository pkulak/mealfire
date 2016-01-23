require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'

Bacon.summary_on_exit

class Recipe
  def to_s
    s = "\n\n"
    
    ingredient_groups.each do |g|
      s << "#{g.name}\n" if g.name
      
      g.ingredients.each do |i|
        s << "-- " if g.name
        s << "#{i.order_by}) #{i.food}\n"
      end
    end
    
    return s
  end
end

describe 'recipes' do
  before do
    TestHelper.reset_database
    
    @recipe = Recipe.create(
      :name => "My Test @recipe",
      :user_id => User.first.id)
  end
  
  it 'adds ingredient lists' do        
    @recipe.add_ingredients %Q{
      1 cup milk
      3 oz horse raddish sauce
      1 cucumber
      some carrots
    }
    
    ingredients = @recipe.ingredient_groups.first.ingredients
    
    ingredients[0].food.should == 'milk'
    ingredients[1].food.should == 'horse raddish sauce'
    ingredients[2].food.should == 'cucumber'
    ingredients[3].food.should == 'some carrots'
    
    ingredients[0].order_by.should == 1
    ingredients[1].order_by.should == 2
    ingredients[2].order_by.should == 3
    ingredients[3].order_by.should == 4
  end
 
  it 'adds ingredient groups' do
    @recipe.add_ingredient_group(name: "First Group")
    
    @recipe.ingredient_groups.first.name.should == 'First Group'
    @recipe.ingredient_groups.first.order_by.should == 1
    
    @recipe.add_ingredient_group(name: "Second Group")
    
    @recipe.ingredient_groups.last.name.should == 'Second Group'
    @recipe.ingredient_groups.last.order_by.should == 2
    
    @recipe.add_ingredients "1 cup milk"    
    @recipe.ingredient_groups.last.ingredients.first.food.should == 'milk'
    
    @recipe.add_ingredients "1 tsp mayo", @recipe.ingredient_groups.first    
    @recipe.ingredient_groups.first.ingredients.first.food.should == 'mayo'
  end
  
  it 'reorders ingredients' do
    @recipe.add_ingredient_group(name: "First Group")
    @recipe.add_ingredients "1 cup milk"
    @recipe.add_ingredients "1 tsp butter"
    
    @recipe.add_ingredient_group(name: "Second Group")
    @recipe.add_ingredients "1 cup water"
    @recipe.add_ingredients "1 tsp horse raddish"
    
    Recipe.change_ingredient_order(
      @recipe.ingredients.last,
      @recipe.ingredient_groups.first,
      nil)
      
    @recipe = Recipe.all.first
        
    @recipe.ingredient_groups.first.ingredients[0].food.should == 'horse raddish'
    @recipe.ingredient_groups.first.ingredients[0].order_by.should == 0
    
    Recipe.change_ingredient_order(
      @recipe.ingredients.last,
      @recipe.ingredient_groups.first,
      @recipe.ingredients[1])
    
    @recipe = Recipe.all.first
    
    @recipe.ingredient_groups.first.ingredients[0].food.should == 'horse raddish'
    @recipe.ingredient_groups.first.ingredients[0].order_by.should == 0
    @recipe.ingredient_groups.first.ingredients[1].food.should == 'milk'
    @recipe.ingredient_groups.first.ingredients[1].order_by.should == 1
    @recipe.ingredient_groups.first.ingredients[2].food.should == 'water'
    @recipe.ingredient_groups.first.ingredients[2].order_by.should == 2
    @recipe.ingredient_groups.first.ingredients[3].food.should == 'butter'
    @recipe.ingredient_groups.first.ingredients[3].order_by.should == 3
  end
  
  it 'reorders ingredient groups' do
    @recipe.add_ingredient_group(name: "First Group")
    @recipe.add_ingredients "1 cup milk"
    @recipe.add_ingredients "1 tsp butter"
    
    @recipe.add_ingredient_group(name: "Second Group")
    @recipe.add_ingredients "1 cup water"
    @recipe.add_ingredients "1 tsp horse raddish"
    
    Recipe.change_ingredient_group_order(@recipe.ingredient_groups[1], nil)
    @recipe = Recipe.all.first
    
    @recipe.ingredient_groups[0].name.should == 'Second Group'
    @recipe.ingredient_groups[1].name.should == 'First Group'
    
    @recipe.add_ingredient_group(name: "Third Group")
    @recipe.add_ingredients "1 tsp salt"
    
    Recipe.change_ingredient_group_order(@recipe.ingredient_groups[2], @recipe.ingredient_groups[0])
    @recipe = Recipe.all.first
    
    @recipe.ingredient_groups[0].name.should == 'Second Group'
    @recipe.ingredient_groups[1].name.should == 'Third Group'
    @recipe.ingredient_groups[2].name.should == 'First Group'
  end
  
  it 'promotes ingredients' do
    @recipe.add_ingredients "1 cup milk"
    @recipe.add_ingredients "1 tsp butter"
    @recipe.add_ingredients "1 cup soda"
    @recipe.add_ingredients "This Is Really a Group"
    @recipe.add_ingredients "1 cup bacon bits"
    @recipe.add_ingredients "1 tsp pepper"
    @recipe.add_ingredient_group(name: 'Sauce')
    @recipe.add_ingredients "1 tsp parika"
    @recipe.add_ingredients "1 cup flour"
    
    Recipe.promote_ingredient(@recipe.ingredients[3])
    @recipe = Recipe.all.first
    
    @recipe.ingredient_groups.length.should == 3
    @recipe.ingredient_groups[1].name.should == 'This Is Really a Group'
    @recipe.ingredient_groups[1].ingredients.length.should == 2
  end
  
  it 'demotes groups' do
    @recipe.add_ingredients "1 cup bacon bits"
    @recipe.add_ingredients "1 tsp pepper"
    @recipe.add_ingredient_group(name: 'Sauce')
    @recipe.add_ingredients "1 tsp paprika"
    @recipe.add_ingredients "1 cup flour"
    
    Recipe.demote_group(@recipe.ingredient_groups[1])
    @recipe = Recipe.all.first
    
    @recipe.ingredients.length.should == 5
    @recipe.ingredients[2].food.should == 'Sauce'
    @recipe.ingredients[3].food.should == 'paprika'
  end
  
  it 'demotes the first group' do
    @recipe.add_ingredient_group(name: 'Sauce')
    @recipe.add_ingredients "1 tsp paprika"
    @recipe.add_ingredients "1 cup flour"
    
    Recipe.demote_group(@recipe.ingredient_groups[0])
    @recipe = Recipe.all.first
    
    @recipe.ingredients.length.should == 3
    @recipe.ingredients[0].food.should == 'Sauce'
    @recipe.ingredients[1].food.should == 'paprika'
    @recipe.ingredients[2].food.should == 'flour'
  end
  
  it 'defrags ingredients' do
    @recipe.add_ingredient_group(name: 'Sauce')
    @recipe.add_ingredients "1 tsp paprika"
    @recipe.add_ingredients "1 cup flour"
    
    @recipe.add_ingredient_group(name: nil)
    @recipe.add_ingredients "1 cup milk"
    @recipe.add_ingredients "pepper"
    
    Recipe.demote_group(@recipe.ingredient_groups[0])
    @recipe = Recipe.all.first
    
    @recipe.defrag
    @recipe = Recipe.all.first
    
    puts @recipe
    
    1.should == 1
  end
end