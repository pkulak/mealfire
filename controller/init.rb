# Define a subclass of Ramaze::Controller holding your defaults for all
# controllers
#require 'helper/authentication_helper'

class Controller < Ramaze::Controller
  helper :xhtml
  helper :authentication
  helper :mealfire
  helper :aspect
  engine :Erubis
  
  layout('default'){|path, wish| !request.xhr?}
end

# Here go your requires for subclasses of Controller:
require 'controller/main'
require 'controller/recipe'
require 'controller/calendar'
require 'controller/shop'
require 'controller/register'
require 'controller/admin'
require 'controller/mobile'
require 'controller/bookmarklet'
require 'controller/store'
require 'controller/api'
require 'controller/user'
require 'controller/api2'