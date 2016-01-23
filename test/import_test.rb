require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'
require 'net/http'
require 'uri'

include Ramaze::Helper::Mealfire

Bacon.summary_on_exit

def open_file(file_name)
  html = File.open('test/recipes/' + file_name + '.html', 'r') do |file|
    file.read
  end
  
  url = html.scan(/^.+\n/)[0].sub('<!--','').sub('-->', '').strip
  
  return url, html
end

def open_url(url)
  uri = URI.parse(url)

  res = Net::HTTP.new(uri.host, uri.port).start do |http|
    path = uri.path
    path << "?" + uri.query if uri.query
    req = Net::HTTP::Get.new(path)
    #req.add_field("Accept-Charset", 'utf-8')
    http.request(req)
  end

  return url, res.body.force_encoding('ISO-8859-1').encode('UTF-8')
end

describe 'the importer' do
  before do
    #TestHelper.reset_database
  end
  
  it 'imports with rdfa' do
    url, html = open_url('http://www.realwomenofphiladelphia.com/user/recipe/cool-ranch-monkey-brains')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 1
    recipe.ingredients.length.should == 21
    recipe.directions.should =~ /Stir in the oil/
    recipe.has_image.should == false
  end
  
  it 'imports from food.com' do
    url, html = open_url('http://www.food.com/recipe/marinated-grilled-new-york-strip-steaks-129403')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 1
    recipe.ingredients.length.should == 8
    recipe.directions.should =~ /Pierce steaks/
    recipe.directions.should !~ %r{\<div class="num"\>1\</div\>}
    recipe.has_image.should == true
    
    url, html = open_url('http://www.food.com/recipe/bahama-mama-89539')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 1
    recipe.ingredients.length.should == 6
    recipe.directions.should =~ /Shake with ice/
    
    url, html = open_url('http://www.food.com/recipe/amazing-chicken-tortilla-soup-108231')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 2
    recipe.ingredients.length.should == 15
    recipe.directions.should =~ /Add all the rest/
    
    url, html = open_url('http://www.food.com/recipe/Tilapia-al-Ajillo-garlic-tilapia-57919')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 1
    recipe.ingredients.length.should == 6
    recipe.directions.should =~ /Season tilapia/
    
    url, html = open_url('http://www.food.com/recipe/1-Hour-Ham-and-Bean-Soup-47924')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 1
    recipe.ingredients.length.should == 10
    recipe.directions.should =~ /Heat vegetable oil in a soup pot./
    
    url, html = open_url('http://www.food.com/recipe/pan-seared-tilapia-with-chile-lime-butter-109163')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)

    recipe.ingredient_groups.length.should == 2
    recipe.ingredients.length.should == 9
    recipe.directions.should =~ /Transfer to a plate and saute/
    
    url, html = open_url('http://www.food.com/recipe/broccoli-and-garlic-pasta-117031')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 1
    recipe.ingredients.length.should == 7
    recipe.directions.should =~ /Cover and cook/
  end
  
  it 'imports from myrecipes.com' do
    url, html = open_url('http://www.myrecipes.com/recipe/banana-breakfast-smoothie-10000000402744/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)

    recipe.ingredients.length.should == 7
    recipe.directions.should =~ /Process all ingredients in a blender/
    recipe.has_image.should == true
    
    url, html = open_url('http://www.myrecipes.com/recipe/bacon-wrapped-pork-tenderloin-10000001723337/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 3
    recipe.directions.should =~ /Remove silver skin from pork/
    recipe.has_image.should == true
    recipe.imported_from.should == 'http://www.myrecipes.com/recipe/bacon-wrapped-pork-tenderloin-10000001723337/'
    
    url, html = open_url('http://www.myrecipes.com/recipe/champion-chicken-parmesan-10000000222386/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)

    recipe.name.should == "Champion Chicken Parmesan"
    recipe.ingredient_groups.length.should == 2
    recipe.ingredient_groups[0].name.should == "Tomato sauce"
    recipe.ingredient_groups[1].name.should == "Chicken"
    recipe.ingredients.length.should == 20
    recipe.directions.should =~ /Heat 1 teaspoon olive oil/
    recipe.has_image.should == true
  end
  
  it 'imports from allrecipes.com' do
    url, html = open_url('http://allrecipes.com/Recipe/Roasted-Beets-and-Sauteed-Beet-Greens/Detail.aspx')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 7
    recipe.directions.should =~ /Preheat the oven to 350 degrees/
    recipe.directions.should =~ /Calories/
    recipe.directions.should =~ /Prep Time:/
    recipe.directions.should =~ /4 servings/
    recipe.has_image.should == true
    recipe.name.should == 'Roasted Beets and Sauteed Beet Greens'
    
    url, html = open_url('http://allrecipes.com/Recipe/Fast-Chicken-Soup-Base/Detail.aspx')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 8
    recipe.directions.should =~ /Bring broth and water to a simmer/
    recipe.has_image.should == true
    recipe.name.should == 'Fast Chicken Soup Base'
  end
  
  it 'imports from epicurious.com' do
    url, html = open_url('http://www.epicurious.com/recipes/food/views/Quinoa-and-Spring-Vegetable-Pilaf-364534')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.has_image.should == false
    recipe.ingredients.length.should == 10
    recipe.ingredient_groups.length.should == 1
    recipe.name.should == 'Quinoa and Spring Vegetable Pilaf'
    recipe.directions.should =~ /Puree broth/
    
    url, html = open_url('http://www.epicurious.com/recipes/food/views/Grilled-Monster-Pork-Chops-with-Tomatillo-and-Green-Apple-Sauce-109529')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 16
    recipe.ingredient_groups.length.should == 2
    recipe.ingredient_groups.first.name.should == 'For pork chops'
    recipe.name.should == 'Grilled Monster Pork Chops with Tomatillo and Green Apple Sauce'
    recipe.directions.should =~ /Simmer tomatillos and/
    
    url, html = open_url('http://www.epicurious.com/recipes/food/views/Sausage-and-White-Bean-Cassoulet-14292')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredient_groups.length.should == 2
    recipe.ingredients.length.should == 13
    recipe.directions.should =~ /In a medium skillet/
    recipe.has_image.should == false
    recipe.name.should =~ /Sausage and White Bean/
        
    url, html = open_url('http://www.epicurious.com/recipes/food/views/Creme-Fraiche-and-Chive-Mashed-Potatoes-355210')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 7
    recipe.directions.should =~ /Bring 3 quarts water to boil/
    recipe.directions.should !~ /Preparation/
    recipe.has_image.should == true
    recipe.name.should =~ /and Chive Mashed Potatoes/
    
    url, html = open_url('http://www.epicurious.com/recipes/food/views/Devils-Food-Cake-with-Peppermint-Frosting-350770')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 22
    recipe.ingredient_groups.length.should == 4
    recipe.ingredient_groups.first.name.should == 'Cake'
    recipe.name.should == "Devil's Food Cake with Peppermint Frosting"
    
    url, html = open_url('http://www.epicurious.com/recipes/food/views/Lemon-Ginger-Cake-with-Pistachios-234444')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 23
    recipe.ingredient_groups.length.should == 3
    recipe.ingredient_groups.first.name.should == 'Lemon curd'
    recipe.name.should == 'Lemon-Ginger Cake with Pistachios'
  end
  
  it 'imports from simplyrecipes.com' do
    url, html = open_url('http://simplyrecipes.com/recipes/asian_coleslaw/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 9
    recipe.ingredient_groups.length.should == 2
    recipe.directions.should =~ /Prepare dressing/
    recipe.has_image.should == true
    recipe.name.should =~ /Asian Coleslaw/
    
    url, html = open_url('http://simplyrecipes.com/recipes/toasted_pumpkin_seeds/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 3
    recipe.ingredient_groups.length.should == 1
    recipe.directions.should =~ /Preheat oven/
    recipe.has_image.should == true
    recipe.name.should =~ /Toasted Pumpkin Seeds/

    url, html = open_url('http://simplyrecipes.com/recipes/easy_shepherds_pie/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 8
    recipe.directions.should =~ /Peel and quarter potatoes/
    recipe.name.should == 'Easy Shepherd\'s Pie'

    url, html = open_url('http://simplyrecipes.com/recipes/chicken_and_dumplings/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
        
    recipe.ingredients.length.should == 22
    recipe.ingredient_groups.length.should == 2
    recipe.directions.should =~ /Heat olive oil/
    recipe.has_image.should == true
    recipe.name.should =~ /Chicken and Dumplings/
    
    url, html = open_url('http://simplyrecipes.com/recipes/roasted_garlic/')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
        
    recipe.ingredients.length.should == 0
    recipe.ingredient_groups.length.should == 0
    recipe.directions.should =~ /Preheat the oven to 400/
    recipe.has_image.should == true
    recipe.name.should =~ /Roasted Garlic/
  end
  
  # http://www.foodnetwork.com/grilling-central-chicken/package/index.html
  it 'imports from foodnetwork' do
    url, html = open_file('foodnetwork2')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 13
    recipe.ingredients.first.food.should == "freshly squeezed orange juice"
    recipe.ingredients.last.food.should == "allspice"
    recipe.ingredient_groups.length.should == 2
    recipe.ingredient_groups[0].name.should == "Marinade"
    recipe.directions.should =~ /Mix the orange juice/
    recipe.has_image.should == true
    recipe.name.should =~ /Honey Orange BBQ Chicken/
    
    url, html = open_file('foodnetwork')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 8
    recipe.ingredients.first.food.should == "ketchup"
    recipe.ingredients.last.food.should == "(3 1/2-pound) chicken, cut into 8 pieces"
    recipe.ingredient_groups.length.should == 1
    recipe.ingredient_groups[0].name.should == ""
    recipe.directions.should =~ /Preheat oven to 375/
    recipe.directions.should =~ /stir together all ingredients/
    recipe.has_image.should == true
    recipe.name.should =~ /The Deen Brothers' BBQ Chicken/
    
    url, html = open_url('http://www.foodnetwork.com/recipes/giada-de-laurentiis/swordfish-with-citrus-pesto-recipe/index.html')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 12
    recipe.ingredient_groups.length.should == 2
    recipe.ingredient_groups[0].name.should == 'Citrus pesto'
    recipe.ingredient_groups[1].name.should == 'Swordfish'
    recipe.directions.should =~ /smooth and creamy/
    recipe.directions.should =~ /Place a grill pan/
    recipe.directions.should =~ /Transfer the grilled swordfish/
    recipe.has_image.should == true
    recipe.name.should =~ /Swordfish With Citrus Pesto/
    
    url, html = open_url('http://www.foodnetwork.com/recipes/bobby-flay/la-burger-recipe/index.html')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 0
    recipe.ingredient_groups.length.should == 0
    recipe.directions.should =~ /Shape 6 ounces/
    recipe.has_image.should == true
    recipe.name.should =~ /L.A. Burger/
    
    url, html = open_url('http://www.foodnetwork.com/recipes/alton-brown/baked-macaroni-and-cheese-recipe/index.html')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 14
    recipe.ingredient_groups.length.should == 2
    recipe.directions.should =~ /Preheat oven to 350/
    recipe.has_image.should == true
    recipe.name.should =~ /Baked Macaroni and Cheese/
    
    url, html = open_url('http://www.foodnetwork.com/recipes/the-surreal-gourmet/grilled-asparagus-spears-recipe/index.html')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 3
    recipe.ingredient_groups.length.should == 1
    recipe.directions.should =~ /Preheat a grill/
    recipe.has_image.should == true
    recipe.name.should =~ /Grilled Asparagus Spears/
  end
  
  it 'imports from martha stewart' do
    url, html = open_url('http://www.marthastewart.com/316859/broiled-salmon-with-spinach-and-feta-sau')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 7
    recipe.ingredient_groups.length.should == 1
    recipe.directions.should =~ /with rack set 4/
    recipe.has_image.should == true
    recipe.name.should =~ /Broiled Salmon with Spinach-and-Feta Saute/
    
    url, html = open_url('http://www.marthastewart.com/339869/johns-three-layer-apple-cake')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 14
    recipe.ingredient_groups.length.should == 2
    recipe.directions.should =~ /and eggs until well combined/
    recipe.has_image.should == true
    recipe.name.should =~ /John's Three-Layer Apple Cake/
    
    url, html = open_url('http://www.marthastewart.com/338295/velvet-cocoa-cake-with-instant-buttercre')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 15
    recipe.ingredient_groups.length.should == 2
    recipe.directions.should =~ /cream butter and sugars until fluffy/
    recipe.has_image.should == true
    recipe.name.should =~ /Velvet Cocoa Cake with Instant Buttercream/
  end
  
  it 'imports from weight watchers' do
    url, html = open_url('http://www.weightwatchers.com/util/art/index_art.aspx?tabnum=1&art_id=106981')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
        
    recipe.ingredients.length.should == 6
    recipe.ingredient_groups.length.should == 1
    recipe.directions.should =~ /In a large bowl, combine chicken with/
    recipe.has_image.should == true
    recipe.name.should == "Yogurt Ranch Chicken Salad Wrap"
    recipe.tags.length.should == 0
    
    url, html = open_url('http://www.weightwatchers.com/food/rcp/index.aspx?recipeid=142391')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
        
    recipe.ingredients.length.should == 9
    recipe.ingredient_groups.length.should == 1
    recipe.directions.should =~ /Place apples in a large bowl/
    recipe.has_image.should == true
    recipe.name.should == "Apple and Carrot Salad"
    recipe.tags.length.should == 1
    recipe.tags.first.name.should == 'side dish'  
    
    url, html = open_url('http://www.weightwatchers.com/food/rcp/index.aspx?recipeid=201189810')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
        
    recipe.ingredients.length.should == 6
    recipe.ingredient_groups.length.should == 1
    recipe.directions.should =~ /honey in small saucepan/
    recipe.has_image.should == false
    recipe.name.should == "Honey Mustard Pork Chops"
    recipe.tags.length.should == 1
    recipe.tags.first.name.should == 'main meal'
  end
  
  it "gets recipe directions even if they aren't notated" do
    url, html = open_url('http://www.joyofbaking.com/FruitSmoothie.html')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients.length.should == 16
    recipe.ingredient_groups.length.should == 4
    recipe.directions.should =~ /I love Fruit Smoothies/
    recipe.has_image.should == true
    recipe.name.should == "Fruit Smoothie Tested Recipe"
  end
  
  it "doesn't pollute ingredients with a shitload of whitespace" do
    url, html = open_url('http://www.food.com/recipe/crock-pot-chicken-cacciatore-41685')
    recipe = MF::Import::Importer.create_recipe(url, html, User.first)
    
    recipe.ingredients[1].food.include?("\r").should == false
  end
end