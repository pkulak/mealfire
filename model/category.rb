class Category < Sequel::Model(:categories)
  def self.split(categories)
    first = []
    last = []
    
    # First, grab the total.
    total = 0
    
    categories.each do |cat|
      cat.children.each{|c| total += 1}
    end
    
    # Now, split.
    index = 0
    
    categories.each do |cat|
      if index < (total / 2)
        first << cat
      else
        last << cat
      end
      
      cat.children.each{|c| index += 1}
    end
    
    return [first, last]
  end
  
  def self.add_data
    Category.columns
    CategoryFinder.columns
    
    categories = [
      ["Produce", [
        'asparagus', 'beet', 'broccoli', 'cauliflower',
        'carrot', 'celery', 'corn cob','cucumber', 'lettuce',
        'mushroom', 'onion', 'green pepper', 'red pepper',
        'yellow pepper', 'potatoe', 'spinach', 'sprout',
        'squash', 'tomatoe', 'zucchini' 'apple', 'avacado',
        'banana', 'berry', 'cherry', 'grape', 'kiwi', 'lemon',
        'lime', 'melon', 'orange', 'peach', 'pear', 'plum'
      ]],
      ["Canned foods", [
        'anchovy', 'applesauce', 'baked bean', 'corn',
        'olive', 'pickle', '\bcan(s|ned)*\b#p=20'
      ]],
      ["Sauces", [
        'sauce', 'salsa', 'syrup', 'worcestershire'
      ]],
      ["Spices and herbs", [
        'basil', 'pepper', 'cilantro', 'garlic', 'oregano',
        'parsly', 'salt', 'spice', 'vanilla extract'
      ]],
      ["Dairy", [
        'butter', 'half & half', 'half and half', 'cream',
        'margarine', 'milk', 'yogurt', 'egg', 'cream cheese',
        'mayo', 'mayonnaise', 'cheddar', 'feta', 'mozzarella',
        'parmesan', 'pepper jack', 'provolone', 'ricotta',
        'swiss', 'cheese'
      ]],
      ["Frozen", [
        'fish sticks', 'ice cream', 'frozen', 'popsicle', 'sorbet'
      ]],
      ["Meat", [
        'bacon', 'beef', 'chicken', 'turkey', 'ham', 'hot dog',
        'brat', 'bratwurst', 'sausage', 'lunchmeat', 'pork',
        'steak'
      ]],
      ["Seafood", [
        'catfish', 'crab', 'lobster', 'halibut', 'oyster',
        'salmon', 'shrimp', 'tilapia', 'tuna'
      ]],
      ["Baked goods", [
        'bagel', 'bun', 'cake', 'cookie', 'croissant', 'donut',
        'bread', 'pastrie', 'pie', 'pita', 'roll'
      ]],
      ["Baking", [
        'sugar', 'icing', 'cake mix', 'brownie mix', 'chocolate chips',
        'cocoa', 'flour', 'oatmeal', 'oats', 'pie shell', 'pie crust',
        'shortening', 'yeast'
      ]],
      ["Snacks and drinks", [
        'candy', 'nuts', 'popcorn', 'chips', 'pudding', 'pretzel',
        'coke', 'pepsi', 'dr pepper', 'sprite', 'soda', 'cola',
        'snacks', 'gatorade', 'crystal light', 'koolaid', 'juice'
      ]],
      ["Personal care", [
        'deodorant', 'antiperspirant', 'soap', 'conditioner', 'condom',
        'tampons', 'floss', 'hair gel', 'hair spray', 'chapstick', 'carmex',
        'lotion', 'mouthwash', 'qtips', 'razor', 'shampoo', 'shaving cream',
        'toilet paper', 'toothpaste'
      ]],
      ["Kitchen", [
        'foil', 'coffee filter', 'disposable cups', 'disposable cutlery',
        'disposable plates', 'bags', 'napkins', 'nonstick spray',
        'toothpicks', 'wax paper'
      ]],
      ["Cleaning products", [
        'cleaner', 'cleanser', 'air freshener', 'bleach', 'dish soap',
        'dishwasher soap', 'dryer sheets', 'fabric softener', 'detergent',
        'paper towels', 'polish'
      ]],
      ["Packaged", [
        'mac.+cheese#p=20'
      ]],
      ["Alcohol", [
        'beer', 'wine', 'vodka'
      ]]
    ]
    
    categories.each do |cat|
      c = Category.create(:name => cat[0])
      
      cat[1].each do |finder|
        CategoryFinder.create(
          :category_id => c.id,
          :expression => finder)
      end
    end
  end
end

# This is used for display only, so I keep it seperate from the database class.
# Really dumb idea, actually.
class CategoryWithChildren
  attr_accessor :children
  
  def initialize(category, ingredient)
    @category = category
    @children = [ingredient]
  end
  
  def deleted
    @children.each do |child|
      return false if !child.deleted
    end
    
    return true
  end
  
  def method_missing(sym, *args, &block)
    @category.send(sym, *args, &block)
  end
end