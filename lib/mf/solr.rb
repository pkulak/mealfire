class MF::Solr
  require 'solr'
  
  unless defined?(SOLR)
    SOLR = Solr::Connection.new('http://localhost:8080/solr', :autocommit => :on)
    RESERVED_WORDS = [
      '+', '-', '||', '!', '(', ')', '{', '}', '[', ']', '^', '"', '~',
      '*', '?', ':', '\\']
  end
  
  def self.user_recipes_dataset(q, user, options = {})
    escape!(q)
    res = SOLR.query %Q{+user_id:#{user.id} +(name:(#{q})^4 tag_name:(#{q})^2 food:(#{q}) directions:(#{q}))}, options
    recipe_ids = res.hits.collect{|h| h['id']}
    
    recipes = Recipe
      .filter(id: recipe_ids)
      .filter('side_dish = 0')
      .filter('deleted = 0')
      
    if recipe_ids.length > 0
      recipes = recipes.order("field (id, #{recipe_ids.join(', ')})".lit)
    end
    
    [recipes, res.total_hits]
  end
  
  def self.user_recipes(q, user, options = {})
    recipes, total = user_recipes_dataset(q, user, options)
    
    recipes = recipes
      .eager(:recipe_tags => :tag)
      .all
    
    [recipes, total]
  end
  
  def self.escape!(query)
    RESERVED_WORDS.each do |r|
      query.gsub!(r, '\\' + r)
    end
    
    query.gsub!('&&', '\\\\&&')
    
    query
  end
end