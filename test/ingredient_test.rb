require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'

include Ramaze::Helper::Mealfire

Bacon.summary_on_exit

class Ingredient
  def to_s  
    ingredient_to_html(self, :html_fraction => false)
  end
end

describe 'an ingredient' do
  before do
    #TestHelper.reset_database
  end
    
  it 'converts units' do
    i = Ingredient.parse("1 cup milk")
    i = i / 8
    i.to_s.should == '2 Tbsp milk'
    
    i = Ingredient.parse("2 Tbsp milk")
    i = i * 2
    i.to_s.should == '1/4 cp milk'
    
    i = Ingredient.parse("1 Tbsp milk")
    i = i / 3
    i.to_s.should == '1 tsp milk'
    
    i = Ingredient.parse("1 tsp milk")
    i = i * 4
    i.to_s.should == '1 Tbsp and 1 tsp milk'
    
    i = Ingredient.parse("2.5 tsp milk")
    i = i * 2
    i.to_s.should == '1 Tbsp and 2 tsp milk'
    
    i = Ingredient.parse('12 oz chicken')
    i = i * 2
    i.to_s.should == '1.5 lb chicken'
    
    i = Ingredient.parse('1 lb chicken')
    i = i / 8
    i.to_s.should == '2 oz chicken'
    
    # Make sure we use the crazy fractions when called for.
    i = Ingredient.parse('1/2 gal milk')
    i = i * 1.25
    ingredient_to_html(i, :html_fraction => false, :all_fractions => true)
      .should == '5/8 gal milk'
      
    i = Ingredient.parse('1 tsp cornstarch')
    i.multiply!(0.4)
    ingredient_to_html(i, :html_fraction => true, :all_fractions => true)
      .should == '&#8535; tsp cornstarch'
      
    i = Ingredient.parse('2 Tbsp low-sodium soy sauce')
    i.multiply!(2)
    ingredient_to_html(i, :html_fraction => true, :all_fractions => true)
      .should == '&#188; cp low-sodium soy sauce'
  end
  
  it 'combines ingredients' do
    test_combo = Proc.new do |first, second, result|
      Ingredient.parse(first)
        .combine_with(Ingredient.parse(second))
        .first
        .to_s
        .should == result
    end
    
    test_combo.call('1 cup milk', '1 cup milk', '2 cp milk')
    test_combo.call('1 cup milk', '1 tbsp milk', '1 cp and 1 Tbsp milk')
    
    # We need to sometimes overestimate how much we need.
    ingredient_to_html(Ingredient.parse('5/8 cup milk'), ceiling: true)
      .should == '2/3 cp milk'
    
    # Not the same dimension, so nothing should happen.
    Ingredient.parse('1 cup milk')
      .combine_with(Ingredient.parse('1 oz milk'))
      .length.should == 2
    
    # Not the same food, so nothing should happen.
    Ingredient.parse('1 cup milk')
      .combine_with(Ingredient.parse('1 cup half and half'))
      .length.should == 2
      
    # Without quantities. haha, I said tities!
    i = Ingredient.parse('cheese').combine_with(Ingredient.parse('cheese')).first
    i.quantity.should == nil
    i.unit.should == nil
    i.food.should == 'cheese'
    
    # Now, combine a whole list.
    all = ["1 cup milk", "2 cups milk", "1 tbsp milk", "1 onion"]
      .collect{|i| Ingredient.parse(i)}
      
    Ingredient.combine_all(all)
      .collect{|i| i.to_s}
      .join(", ")
      .should == "3 cp and 1 Tbsp milk, 1 onion"
    
    i = Ingredient.parse('onion').combine_with(Ingredient.parse('1 onion')).first
    i.quantity.should == 1
    i.unit.should == nil
    i.food.should == 'onion'
    
    i = Ingredient.parse('1 onion').combine_with(Ingredient.parse('1 cup onion'))
    i.length.should == 2
    
    i = Ingredient.parse('1 onion').combine_with(Ingredient.parse('2 onions'))
    i.length.should == 1
    i[0].quantity.should == 3
    i[0].food.should == 'onions'
  end
  
  it 'combines crazy' do
    i = Ingredient.parse('tsp salt').combine_with(Ingredient.parse('2/3 Tbsp salt'))
    i.length.should == 1
    i[0].to_s.should == '1 Tbsp salt'
    
    i = Ingredient.parse('1 tsp salt').combine_with(Ingredient.parse('tsp salt'))
    i.length.should == 1
    i[0].quantity.should == 2
    i[0].food.should == 'salt'
  end
  
  it 'parses strings with whitespace' do
    i = Ingredient.parse("     1  cup   milk   \n\n")
    
    i.quantity.should == 1
    i.unit.abbr.should == 'cp'
    i.food.should == 'milk'
  end
  
  it 'parses quartered chicken' do
    i = Ingredient.parse("1 quartered chicken")
    
    i.quantity.should == 1
    i.unit.should == nil
    i.food.should == 'quartered chicken'
    
    i = Ingredient.parse("1 quart milk")
    
    i.quantity.should == 1
    i.unit.abbr.should == 'qt'
    i.food.should == 'milk'
  end
  
  it 'parses incomplete strings' do
    i = Ingredient.parse("1 cucumber")
    
    i.quantity.should == 1
    i.unit.should == nil
    i.food.should == 'cucumber'
    
    i = Ingredient.parse("some broccoli")
    
    i.quantity.should == nil
    i.unit.should == nil
    i.food.should == 'some broccoli'
  end
  
  it 'parses strings with crap at the front' do
    ['* 1 cp milk', '- 1 cup milk'].each do |s|
      i = Ingredient.parse(s)
      i.quantity.should == 1
      i.unit.abbr.should == 'cp'
      i.food.should == 'milk'
    end
  end
  
  it 'parses strings' do
    ingredients = [
      Ingredient.parse("1 and 1/2 cup milk"),
      Ingredient.parse("1.5 cups of milk"),
      Ingredient.parse("3/2 cups milk"),
      Ingredient.parse("3/2 of a cup of milk"),
      Ingredient.parse("3/2 C of milk")
    ]
    
    ingredients.each do |i|    
      i.quantity.should == 1.5
      i.unit.abbr.should == 'cp'
      i.food.should == 'milk'
    end
    
    check_parse = lambda do |string, q, u, food|
      i = Ingredient.parse(string)
      i.quantity.should == q
      
      if u == nil
        i.unit.should == nil
      else
        i.unit.abbr.should == u
      end
      
      i.food.should == food
    end
    
    check_parse.call('1 3/4 tbsp of butter', 1.75, 'Tbsp', 'butter')
    check_parse.call('1 pound 1/2 cherries, 1/2 blueberries mix', 1, 'lb', '1/2 cherries, 1/2 blueberries mix')
    check_parse.call('1 tsp salt', 1, 'tsp', 'salt')
    check_parse.call('1 / 4 cup milk', 0.25, 'cp', 'milk')
    check_parse.call('1 milk cup', 1, nil, 'milk cup')
    check_parse.call('1 T milk', 1, 'Tbsp', 'milk')
    check_parse.call('1 t milk', 1, 'tsp', 'milk')
    check_parse.call('1 T. milk', 1, 'Tbsp', 'milk')
    check_parse.call('3 lbs bacon', 3, 'lb', 'bacon')
    check_parse.call('.5 cups milk', 0.5, 'cp', 'milk')
    check_parse.call('.5.1 cups milk', 0.5, 'cp', 'milk')
    check_parse.call('3 cup(s) milk', 3, 'cp', 'milk')
    
    i = Ingredient.parse('1 Tbsp and 1 tsp milk')
    i.quantity.should.be.close 0.01, 1.33
    i.unit.abbr.should == 'Tbsp'
    i.food.should == 'milk'
    
    Ingredient.parse('1 cup plus 2 Tbsp flour').to_s.should == "1 cp and 2 Tbsp flour"
  end
  
  it 'parses strings with descriptions' do
    i = Ingredient.parse('1 lb chicken (cut into half-inch cubes)')
    i.quantity.should == 1
    i.unit.abbr.should == 'lb'
    i.food.should == 'chicken (cut into half-inch cubes)'
    
    # This is evil, no more of this shit.
    # i.description.should == 'cut into half-inch cubes'
  end
  
  it 'parses strings with ranges' do
    [Ingredient.parse('3-4 apples'), Ingredient.parse("3 to 4 apples")].each do |i|
      i.quantity.should == 3
      i.range.should == 4
      i.food.should == "apples"
    end
    
    i = Ingredient.parse('3-4 cups of milk')
    i.quantity.should == 3
    i.unit.abbr.should == 'cp'
    i.range.should == 4
    i.food.should == 'milk'
  end
  
  it 'prints ingredients with ranges' do
    Ingredient.parse('3-4 cups of milk').to_s.should == '3-4 cp milk'
    Ingredient.parse('3 to 4 cups of milk').to_s.should == '3-4 cp milk'
    Ingredient.parse('.5 to 3 apples').to_s.should == '1/2-3 apples'
  end
  
  it 'combines ingredients with ranges' do
    i = Ingredient.parse('2-3 apples')
      .combine_with(Ingredient.parse('1 apple')).first
    
    i.quantity.should == 3
    i.range.should == 4
    i.food.should == 'apples'
  
    i = Ingredient.parse('2-3 apples')
      .combine_with(Ingredient.parse('1-2 apples')).first
    
    i.quantity.should == 3
    i.range.should == 5
    i.food.should == 'apples'
    
    i = Ingredient.parse('2-3 pounds chicken')
      .combine_with(Ingredient.parse('8 oz chicken')).first
    
    i.quantity.should.be.close 2.49, 2.51
    i.range.should.be.close 3.49, 3.51
    i.unit.abbr.should == 'lb'
    i.food.should == 'chicken'
  end
  
  it 'splits ingredients' do
    Ingredient.parse('1.65 cup flour').to_s.should == "1 1/2 cp and 2 Tbsp flour"
    Ingredient.parse('1.02 cup flour').to_s.should == "1 cp and 1 tsp flour"
    Ingredient.parse('1 1/3 Tbsp flour').to_s.should == "1 Tbsp and 1 tsp flour"
    
    ingredient_to_html(Ingredient.parse('3/4 cup butter'), multiplier: 0.5)
      .should == '1/3 cp and 2 tsp butter'
  end
  
  it 'parses strings with number signs' do
    i = Ingredient.parse('#4 Coffee Filters')
    
    i.quantity.should == nil
    i.unit.should == nil
    i.food.should == '#4 Coffee Filters'
  end
  
  it 'avoids zero quantities' do
    i = Ingredient.parse('1/8 cup milk')
    i.to_s.should == '2 Tbsp milk'
  end
  
  it 'parses strings with fraction characters' do
    i = Ingredient.parse('&#8539; cup milk')
    i.to_s.should == '2 Tbsp milk'
    
    i = Ingredient.parse('1&#188; cup milk')
    i.to_s.should == '1 1/4 cp milk'
    
    i = Ingredient.parse('&#xBE; cup milk')
    i.to_s.should == '3/4 cp milk'
    
    i = Ingredient.parse("\u00BE cup milk")
    i.to_s.should == '3/4 cp milk'
  end
end