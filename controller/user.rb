class UserController < Controller
  def api_redirect
    if !current_user.authed?
      session[:next] = "/user/api_redirect?#{{to: request[:to]}.to_query}"
      return redirect "/login"
    end
    
    session = ApiSession[authed_user_id: current_user.authed_user.id, created_by: 'www.mealfire.com']
    
    unless session
      session = ApiSession.create_for_user(current_user, 'www.mealfire.com')
    end
    
    path, query = request[:to].split('?')
    
    if query
      query = Rack::Utils.parse_query(query)
      query[:token] = session.token
    else
      query = {token: session.token}
    end
    
    redirect "#{path}?#{query.to_query}"
  end
  
  def index
    @user = User[id: request[:id]].required
    
    if !@user.authed?
      raise UserException.new("No Profile", "This user doesn't have a profile yet.")
    end
    
    @recipes = Recipe
      .filter(user_id: request[:id], is_public: true, hidden: false, side_dish: false, deleted: false)
      .eager(:recipe_tags => :tag)
      .order(:id.desc)
      
    @recipes = MF::Paginator.new(
      dataset: @recipes,
      current_page: current_page,
      per_page: 20)

    @user_tags = Tag.user_tags(@user, :sort => :total)
    
    @make_path = Proc.new do |page|
      "/user/#{@user.id}?page=#{page}"
    end
    
    @title = "#{@user.name}"
  end
end
