RACK_ENV = 'test'

require File.expand_path('../app.rb', File.dirname(__FILE__))

class TestHelper
  def self.reset_database
    `/usr/local/mysql/bin/mysqldump -u root mealfire --no-data=true | /usr/local/mysql/bin/mysql -u root mealfire_test`
    
    Unit.add_data
    Category.add_data
    User.create(:created_at => Time.now)
  end
end