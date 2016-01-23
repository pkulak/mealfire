module Ramaze
  module Helper
    module Authentication
      def current_user
        unless @current_user
          @current_user = UserProxy.new(session, request.ip)
        end
        
        @current_user
      end
      
      def login_user(user)
        session[:user_id] = user.id
        @current_user = user
      end
      
      def logout_user
        session[:user_id] = nil
        session[:just_logged_out] = true
        @current_user = nil
      end
    end
  end
end