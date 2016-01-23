require 'sequel'
require 'active_support/inflector' # http://code.google.com/p/ruby-sequel/issues/detail?id=329

Sequel::Model.plugin(:schema)
Sequel.extension :pagination

if RACK_ENV == 'production'
  DB = Sequel.mysql('mealfire',
    :user => 'mealfire',
    :password => '...',
    :host => 'localhost',
    :encoding => 'utf8')
elsif RACK_ENV == 'development'
  DB = Sequel.mysql('mealfire',
    :user => 'mealfire',
    :password => '...',
    :host => 'localhost',
    :encoding => 'utf8')
elsif RACK_ENV == 'test'
  DB = Sequel.mysql('mealfire_test',
    :user => 'mealfire',
    :password => '...',
    :host => 'localhost',
    :encoding => 'utf8')
end

#DB.loggers << Logger.new("log/#{RACK_ENV}_sql.log")

# Extend Sequel::Model with some custom coolness.
Sequel::Model.send(:include, MF::Model)

class Sequel::Model
  plugin :force_encoding
  self.forced_encoding = 'UTF-8'
  
  def required
    return self
  end
end

# Plugins
require 'model/plugins/json'
require 'model/plugins/serialize'

# Here go your requires for models:
require 'model/food'
require 'model/ingredient'
require 'model/ingredient_group'
require 'model/unit'
require 'model/user'
require 'model/authed_user'
require 'model/recipe'
require 'model/tag'
require 'model/recipe_tag'
require 'model/recipe_day'
require 'model/ip_log'
require 'model/shopping_list_item'
require 'model/category'
require 'model/category_finder'
require 'model/password_reset'
require 'model/recipe_share'
require 'model/saved_list'
require 'model/saved_food'
require 'model/store'
require 'model/api_session'
require 'model/user_proxy'
require 'model/rating'
require 'model/error_log'