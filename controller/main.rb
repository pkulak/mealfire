class MainController < Controller
  def rate_recipe_day
    rd = RecipeDay[request[:id]].required

    unless rd.user == current_user
      respond "Security Error", 400
    end
    
    rd.rate(request[:value].to_f)
    respond "OK"
  end
  
  def skip_rating_recipe_day
    rd = RecipeDay[request[:id]]

    unless rd.user == current_user
      respond "Security Error", 400
    end
    
    rd.is_rated = true
    rd.save
  end
  
  def sitemap    
    # Find all the profiles that have collected a video.
    sql = %Q{
      SELECT users.id, (
        select max(updated_at)
        from recipes
        where user_id = users.id and is_public = true) updated
      FROM `users`
        INNER JOIN `authed_users` ON (`authed_users`.`user_id` = `users`.`id`)
      WHERE (exists (
        select *
        from recipes
        where user_id = users.id and is_public = true))}
        
    xml = '<?xml version="1.0" encoding="UTF-8"?>'
    xml << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    
    DB.fetch(sql) do |row|
      xml << "<url>"
      xml << "<loc>http://mealfire.com/user/#{row[:id]}</loc>"
      xml << "<lastmod>#{row[:updated].strftime('%Y-%m-%d')}</lastmod>"
      xml << "</url>"
    end
    
    xml << '</urlset>'
    
    respond xml, 200, {'Content-Type' => 'text/xml'}
  end
  
  def change_name
    must_be_authed(:raise_exception => true)
    
    if request[:name].blank?
      flash[:notice] = UserException.missing('Name').to_a
      redirect '/account'
    end
    
    current_user.name = request[:name]
    current_user.timezone = request[:timezone]
    current_user.rate_recipes = request[:rate_recipes] == 'true'
    current_user.authed_user.save
    
    flash[:notice] = ['Account Updated', "Your account has been updated."]
    redirect '/account'
  end
  
  def change_email
    must_be_authed(:raise_exception => true)
    
    if request[:password].blank?
      flash[:notice] = UserException.missing('Password').to_a
      redirect '/account'
    end
    
    if request[:email].blank?
      flash[:notice] = UserException.missing('Email Address').to_a
      redirect '/account'
    end
    
    if !current_user.check_password(request[:password])
      flash[:notice] = ['Bad Password', "The password you've entered is incorrect."]
      redirect '/account'
    end
    
    if u = AuthedUser[email: request[:email].downcase] and u.id != current_user.authed_user.id
      flash[:notice] = ['Email Taken', "The email address you've entered is already taken."]
      redirect '/account'
    end
    
    current_user.email = request[:email]
    current_user.authed_user.save
    
    flash[:notice] = ['Email Changed', "Your email address has been changed."]
    redirect '/account'
  end
  
  def edit_account
    must_be_authed(:raise_exception => true)
    
    if request[:name].blank?
      flash[:notice] = UserException.missing('Name').to_a
      redirect '/account'
    end
    
    if request[:email].blank?
      flash[:notice] = UserException.missing('Email Address').to_a
      redirect '/account'
    end
    
    request[:email] = request[:email].strip.downcase
    
    if request[:email] != current_user.email
      if AuthedUser[:email => request[:email]]
        flash[:notice] = ["Email in Use", "The email address you have chosen is already in use."]
        redirect '/account'
      end
      
      current_user.authed_user.email = request[:email]
    end
    
    current_user.authed_user.name = request[:name]
    current_user.authed_user.save
    
    flash[:notice] = ["Account Updated", "Your account has been updated."]
    redirect '/account'
  end
  
  def change_password
    must_be_authed(:raise_exception => true)
    
    if request[:current].blank?
      flash[:notice] = UserException.missing('Current Password').to_a
      redirect '/account'
    end
    
    if request[:new].blank?
      flash[:notice] = UserException.missing('New Password').to_a
      redirect '/account'
    end
    
    if !current_user.check_password(request[:current])
      flash[:notice] = ["Bad Password", 'The "current password" you\'ve entered is not corrent.']
      redirect '/account'
    end
    
    current_user.authed_user.change_password(request[:new])
    current_user.authed_user.save
    
    flash[:notice] = ["Password Changed", "Your password has been changed."]
    redirect '/account'
  end
  
  def account
    must_be_authed
  end
  
  def password
    must_be_guest
    @title = "Retrieve Password"
    
    return unless request.post?
    
    email = request[:email]
    
    if email.blank?
      return flash.previous[:notice] = UserException.missing('Email').to_a
    end
    
    user = AuthedUser[:email => email]
    
    if !user
      return flash.previous[:notice] = ["Email Not Found",
        "The email you have entered does not exist in our system."]
    end
    
    prev = PasswordReset.filter(
      "authed_user_id = ? and created_at > ?",
      user.id, 1.hour.ago)
    
    if prev.count > 1
      return flash.previous[:notice] = ["Too Many Resets",
        "This account has recently had its password reset. Please check your " +
        "email for instructions."]
    end
    
    reset = PasswordReset.create(:authed_user_id => user.id)
    
    message = "Please click on the following link to reset your Mealfire password:\n\n" +
      "http://#{DOMAIN}/reset_password/#{reset.rand}\n\n" +
      "If you didn't request a password reset at Mealfire, please disregard this email."
    
    send_mail(to: user, subject: "Mealfire Password Reset", text_body: message)
    
    flash[:notice] = ["Email Sent",
      "Please check your email for instrucions on how to reset your password."]
    
    redirect '/login'
  end
  
  def reset_password(rand)
    must_be_guest
    @pr = PasswordReset[:rand => rand]
    
    if !@pr
      raise UserException.new("URL Error",
        "The password reset URL entered is invalid. This could be " +
        "because it was copied and pasted from your email client incorrectly.")
    end
    
    if @pr.created_at < 120.minutes.ago || @pr.followed
      raise UserException.new("Reset Expired", "The password reset has expired.")
    end
    
    if request.post?
      if request[:password].blank?
        return flash.previous[:notice] = UserException.missing('Password').to_a
      end
      
      @pr.authed_user.change_password(request[:password])
      @pr.authed_user.save
      @pr.followed = true
      @pr.save
      
      flash[:notice] = ["Password Reset", "Your password has been reset. " +
        "You can now use it to login."]
        
      redirect '/login'
    end
  end
  
  def close_warning
    session[:disable_warning] = true
  end
  
  def close_browser_warning
    session[:disable_browser_warning] = true
  end
  
  def error
    @title = "System Error"
    e = request.env[Rack::RouteExceptions::EXCEPTION]
    ErrorLog.record_error(exception: e, type: 'SITE', user: current_user, request: request)
    return unless e
  end
  
  def user_error
    @error = request.env[Rack::RouteExceptions::EXCEPTION]
    
    unless @error.is_a?(UserException)
      @error = UserException.new("System Error", "")
    end
    
    @title = @error.heading
  end
  
  def api_error
    @error = request.env[Rack::RouteExceptions::EXCEPTION]
    respond [false, @error.message].to_json
  end
  
  def cant_view_imported_recipe
    @title = "Error"
    @recipe = request.env[Rack::RouteExceptions::EXCEPTION].recipe
  end
  
  def cant_view_private_recipe
    session[:next] = recipe_url(request.env[Rack::RouteExceptions::EXCEPTION].recipe)
    @title = "Private Recipe"
  end
  
  def contact
    @title = 'Contact'
    return unless request.post?
    
    if current_user.authed?
      name = current_user.name
      email = current_user.email
    else
      name = request[:name]
      email = request[:email]
      
      if name.blank?
        return flash.previous[:notice] = UserException.missing("Name").to_a
      end
      
      if email.blank?
        return flash.previous[:notice] = UserException.missing("Email").to_a
      end
    end
    
    send_mail(
      to: {name: 'Mealfire Support', email: 'support@mealfire.com'},
      from: {name: 'Mealfire Support', email: 'gmailhack@mealfire.com'},
      reply_to: {name: name, email: email},
      subject: 'Mealfire Contact Form',
      text_body: request[:text])
    
    flash[:notice] = ['Thank You',
      'Thank you for your feedback. Someone will get back to you shortly.']
    
    redirect '/calendar'
  end
  
  def index
    if request.env["HTTP_USER_AGENT"] =~ /iPhone/ || request.env["HTTP_USER_AGENT"] =~ /Android/
      redirect "/mobile"
    elsif current_user.authed?
      redirect "/calendar"
    end
  end
  
  def finders
    @finders = current_user.category_finders
  end
  
  def delete_finder
    CategoryFinder[:user_id => current_user.id, :id => request[:id]].destroy
    redirect '/finders'
  end
  
  def login
    must_be_guest
    @title = "Login"
    
    if request.post?
      begin
        login_user(User.authenticate(request[:email], request[:password]))
      rescue UserException => e
        return flash.previous[:notice] = e.to_a
      end
      
      if session[:next]
        n = session[:next]
        session[:next] = nil
        redirect n
      else
        redirect '/calendar'
      end
    end
  end
  
  def logout
    logout_user
    redirect '/'
  end
end
