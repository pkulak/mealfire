class PasswordReset < Sequel::Model(:password_resets)
  many_to_one :authed_user
  
  def before_create
    return false if super == false
    self.created_at = Time.now
    self.rand = MF::Math.random_string(10)
  end
end