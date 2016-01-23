class RegisterController < Controller
  map '/register'
  
  def index
    must_be_guest
    @title = 'Register'

    return unless request.post?

    begin
      authed_user = User.create_authed_user(current_user, {
        :name => request[:name],
        :email => request[:email],
        :password => request[:password]
      })
    rescue UserException => e
      flash.previous[:notice] = e.to_a
      return
    end
    
    authed_user.transaction_id = session[:referrer] || 'BETA'
    authed_user.save
    redirect '/calendar'
  end
end