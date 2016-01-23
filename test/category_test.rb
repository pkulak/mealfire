require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'

include Ramaze::Helper::Mealfire

Bacon.summary_on_exit

describe 'a category' do
  before do
    TestHelper.reset_database
  end
  
  it 'categorizes ingredients' do
    ingredient = Ingredient.parse('Juice from one date')
    user = User.first
    
    user.find_category(ingredient).category.name.should == 'Snacks and drinks'
    
    # Now, I'm going to say that a "date" is produce. It should take priority.
    user.change_category('Juice from one date', 'date', Category[name: 'Produce'])
    user.reload
    user.find_category(ingredient).category.name.should == 'Produce'
    
    # Ah, but actually, juice is always for making alcohol in my house!
    user.change_category('Juice from one date', 'Juice from', Category[name: 'Alcohol'])
    user.reload
    user.find_category(ingredient).category.name.should == 'Alcohol'
    
    # There should now be both finders because "date" still has a lower priority.
    CategoryFinder.where(user_id: user.id).count.should == 2
    
    # Eh, juice really should be a drink.
    user.change_category('Juice from one date', 'Juice', Category[name: 'Snacks and drinks'])
    user.reload
    user.find_category(ingredient).category.name.should == 'Snacks and drinks'
    
    # There should still only be 2 finders, since "Juice from" got deleted.
    CategoryFinder.where(user_id: user.id).count.should == 2
  end
  
  it 'finds from ingredients' do
    Category.find_category(
      Ingredient.parse("1 cup chopped onion"))
      .name.should == 'Fresh vegetables'
    
    Category.find_category(
      Ingredient.parse("1 Tbsp pepper"))
      .name.should == 'Spices and herbs'
    
    Category.find_category(
      Ingredient.parse("1 Green Pepper"))
      .name.should == 'Fresh vegetables'
      
    Category.find_category(
      Ingredient.parse("Dr. Pepper"))
      .name.should == 'Snacks and drinks'
      
    Category.find_category(
      Ingredient.parse("can condensed french onion soup"))
      .name.should == 'Canned foods'
    
    Category.find_category(
      Ingredient.parse("some canned half and half"))
      .name.should == 'Canned foods'
    
    Category.find_category(
      Ingredient.parse("mac n cheese"))
      .name.should == 'Packaged'
    
    Category.find_category(
      Ingredient.parse("macaroni and cheese"))
      .name.should == 'Packaged'
    
    Category.find_category(
      Ingredient.parse("mac 'n' cheese"))
      .name.should == 'Packaged'
    
    Category.find_category(
      Ingredient.parse("cans peeled and diced tomatoes"))
      .name.should == 'Canned foods'
  end
end