require File.expand_path('app.rb', File.dirname(__FILE__))

WORDS = [
  "a", "ac", "adipiscing", "aliquam", "amet", "ante", "arcu", "at", "auctor",
  "bibendum", "blandit", "consectetur", "cras", "dapibus", "diam", "dictum",
  "dolor", "donec", "egestas", "eget", "elementum", "elit", "erat", "est",
  "et", "eu", "euismod", "facilisi", "faucibus", "hendrerit", "in",
  "interdum", "ipsum", "laoreet", "leo", "libero", "ligula", "lorem",
  "maecenas", "magna", "malesuada", "massa", "mattis", "metus", "mi", "mollis",
  "nec", "neque", "nisl", "non", "nulla", "nunc", "pellentesque", "phasellus",
  "porta", "praesent", "purus", "quis", "sapien", "sed", "sem", "semper",
  "sit", "sodales", "sollicitudin", "tempor", "tortor", "turpis", "ultrices",
  "ultricies", "urna", "ut", "varius", "vel", "venenatis", "vestibulum",
  "vitae", "vivamus", "volutpat"]

TAGS = %W[lunch dinner breakfast snack appetizer sandwich supper desert meat bbq brunch fruit]

def get_random_words(count)
  ret = []
  
  0.upto(count) do
    ret << WORDS[rand(WORDS.length)]
  end
  
  ret.join(' ')
end

(0..10).each do
  r = Recipe.create(
    :name => get_random_words(rand(5)),
    :user_id => 1)
  
  group = IngredientGroup.create(
    :name => nil,
    :recipe_id => r.id,
    :order_by => 0)
  
  (0..rand(25)).each do
    i = Ingredient.create(
      :quantity => rand(5),
      :unit => Unit[rand(6)],
      :food => get_random_words(rand(3)),
      :ingredient_group_id => group.id,
      :order_by => group.max_ingredient_order + 1)
  end
  
  r.directions = get_random_words(rand(100))
  r.save
  
  (0..rand(3)).each do
    r.add_tag(TAGS[rand(TAGS.length)])
  end
end