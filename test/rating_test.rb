require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'

Bacon.summary_on_exit

describe 'recipe rating' do
  before do
    TestHelper.reset_database
    
    @recipe = Recipe.create(
      name: "My Test @recipe",
      user_id: User.first.id)
  end
end