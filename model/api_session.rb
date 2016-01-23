class ApiSession < Sequel::Model(:api_sessions)
  many_to_one :authed_user
  updates_date_fields
  
  def self.create_for_user(user, created_by = nil)
    ApiSession.create(
      authed_user_id: user.authed_user.id,
      token: MF::Math.random_string(40),
      last_login: Time.now,
      created_by: created_by)
  end
end