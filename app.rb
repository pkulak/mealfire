# This file contains your application, it requires dependencies and necessary
# parts of the application.
#
# It will be required from either `config.ru` or `start.rb`

# Globals
AWS_ACCESS_KEY = '...'
AWS_SECRET_KEY = '...'
POSTMARK_KEY = '...'

RACK_ENV = ENV['RACK_ENV'] || 'development' unless defined?(RACK_ENV)
DOMAIN = RACK_ENV == 'development' ? 'localhost:7000' : 'mealfire.com'

Encoding.default_internal, Encoding.default_external = ['utf-8'] * 2

require 'rubygems'
require 'ramaze'
require 'nokogiri'
require 'json'
require 'net/smtp'
require 'ruby-debug' if RACK_ENV == 'development' || RACK_ENV == 'test'
require 'yaml'
require 'ri_cal'
require 'digest/sha1'
require 'tzinfo'
require 'aws/s3'
require 'RMagick'
require 'tempfile'
require 'active_support/lazy_load_hooks'
require 'active_support/core_ext/string'

if RACK_ENV == 'production'
  Ramaze.options.mode = :live
end

# Add the directory this file resides in to the load path, so you can run the
# app from any other working directory
$LOAD_PATH.unshift(__DIR__)

# Custom requires
require 'lib/std_lib'
require 'lib/mf/math'
require 'lib/mf/s3'
require 'lib/mf/month'
require 'lib/mf/sanitizer'
require 'lib/mf/model'
require 'lib/mf/innate'
require 'lib/mf/mailer'
require 'lib/mf/paginator'
require 'lib/mf/import/init'
require 'lib/mf/jsonp'
require 'lib/mf/solr'
require 'lib/mf/api/include_node'

# Initialize controllers and models
require 'model/init'
require 'controller/init'

if RACK_ENV == 'production'
  Ramaze.options.cache.session = Ramaze::Cache::MemCache
  Ramaze.options.cache = Ramaze::Cache::MemCache
elsif RACK_ENV == 'development'
  Ramaze.options.cache.session = Ramaze::Cache::YAML
  Ramaze.options.cache = Ramaze::Cache::YAML
end

Rack::RouteExceptions.route(UserException, '/user_error')
Rack::RouteExceptions.route(ApiException, '/api_error')
Rack::RouteExceptions.route(ImportedRecipeViewException, '/cant_view_imported_recipe')
Rack::RouteExceptions.route(PrivateRecipeViewException, '/cant_view_private_recipe')

if RACK_ENV == 'production'
  Rack::RouteExceptions.route(Exception, '/error')
end

# Middleware
Ramaze.middleware! :dev do |m|
  m.use Rack::Mealfire::JSONP
  m.use Rack::Lint
  m.use Rack::CommonLogger, Ramaze::Log
  m.use Rack::ShowExceptions
  m.use Rack::ShowStatus
  m.use Rack::RouteExceptions
  m.use Rack::ConditionalGet
  m.use Rack::ETag, 'public'
  m.use Rack::Head
  m.use Ramaze::Reloader
  m.run Ramaze::AppMap
end

Ramaze.middleware! :live do |m|
  m.use Rack::Mealfire::JSONP
  m.use Rack::CommonLogger, Ramaze::Log
  m.use Rack::RouteExceptions
  m.use Rack::ShowStatus
  m.use Rack::ConditionalGet
  m.use Rack::ETag, 'public'
  m.use Rack::Head
  m.run Ramaze::AppMap
end

# Routing
Ramaze::Route['/extras'] = '/shop'

Ramaze::Route('calendar export') do |path, request|
  matches = path.scan(/\/calendar\/(.+)\.ics$/i)
  
  if matches.length > 0
    request[:salt] = matches[0][0]
    '/calendar/export'
  end
end

Ramaze::Route('recipe view') do |path, request|
  matches = path.scan(/\/recipe\/(\d+)$/i)
  
  if matches.length > 0
    request[:id] = matches[0][0]
    '/recipe/edit'
  end
end

Ramaze::Route('recipe cook') do |path, request|
  matches = path.scan(/\/recipe\/cook\/([\d,:\.]+)$/i)
  
  if matches.length > 0
    request[:ids] = matches[0][0]
    '/recipe/cook'
  end
end

Ramaze::Route('store edit') do |path, request|
  matches = path.scan(/\/store\/(\d+)$/i)
  
  if matches.length > 0
    request[:id] = matches[0][0]
    '/store/new'
  end
end

Ramaze::Route('view recipe share') do |path, request|
  matches = path.scan(%r!/r/(.+)$!)
  
  if matches.length > 0
    "/recipe/view/#{matches[0][0]}"
  end
end

# These routes are to get around the damn action(id) flaw.
Ramaze::Route('recipe edit') do |path, request|
  matches = path.scan(/\/recipe\/edit\/(.+)$/i)
  
  if matches.length > 0
    request[:id] = matches[0][0]
    '/recipe/edit'
  end
end

Ramaze::Route('recipe print') do |path, request|
  matches = path.scan(/\/recipe\/print\/(.+)$/i)
  
  if matches.length > 0
    request[:id] = matches[0][0]
    '/recipe/print'
  end
end

Ramaze::Route('calendar inline recipe') do |path, request|
  matches = path.scan(/\/calendar\/_recipe\/(.+)$/i)
  
  if matches.length > 0
    request[:id] = matches[0][0]
    '/calendar/_recipe'
  end
end

Ramaze::Route('user index') do |path, request|
  matches = path.scan(/\/user\/(\d+)$/i)
  
  if matches.length > 0
    request[:id] = matches[0][0]
    '/user'
  end
end

Ramaze::Route('sitemap') do |path, request|
  if path.downcase == '/sitemap.xml'
    '/sitemap'
  end
end

Ramaze::Route[ %r!/recipe/view_share/(.+)$! ] = "/recipe/view/%s"
Ramaze::Route[ %r!/api/v2/(.+)$! ] = "/api2/%s"
