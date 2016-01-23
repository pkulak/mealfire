class AuthedUser < Sequel::Model(:authed_users)  
  many_to_one :user
  updates_date_fields
  
  def change_password(new_password)
    salt = User.generate_salt
    password = User.encrypt_password(new_password, salt)
    
    self.salt = salt
    self.password = password
  end
end