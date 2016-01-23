class UserProxy
  attr_accessor :session, :ip
  
  def initialize(session, ip)
    self.session = session
    self.ip = ip
  end
  
  def ==(rhs)
    (rhs.is_a?(UserProxy) || rhs.is_a?(User)) && self.id == rhs.id
  end
  
  def !=(rhs)
    !(self == rhs)
  end
  
  def virgin?
    session[:user_id] == nil
  end
  
  def stores
    virgin? ? [] : user.stores
  end
  
  def has_imported
    virgin? ? false : user.has_imported
  end
  
  def adjust_time(t)
    virgin? ? t : user.adjust_time(t)
  end
  
  def authed?
    virgin? ? false : user.authed?
  end
  
  def id
    if session[:user_id]
      session[:user_id]
    else
      user.id
    end
  end
  
  def user
    return @user if @user
    
    if session[:user_id]
      @user = User[session[:user_id]]
      
      if @user
        return @user
      else
        session[:user_id] = nil
      end
    end
    
    @user = User.create(:ip => self.ip)
    self.session[:user_id] = @user.id
    IPLog.create(:user_id => @user.id, :ip => self.ip)
    
    # Log the IP address, if it's changed.
    if @user.ip != self.ip
      IPLog.create(:user_id => self.user.id, :ip => self.ip)
      @user.ip = self.ip
      @user.save
    end
    
    return @user
  end
  
  def user=(rhs)
    @user = rhs
  end
   
  def method_missing(sym, *args, &block)
    user.send(sym, *args, &block)
  end
end