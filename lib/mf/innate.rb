module Innate
  module Helper
    module Redirect
      def redirect_with_host(target, options = {})
        redirect_without_host(target, options.merge(
          :host => 'mealfire.com',
          :port => 80))
      end
      
      if RACK_ENV == 'production'
        alias_method :redirect_without_host, :redirect
        alias_method :redirect, :redirect_with_host
      end
    end
  end
end