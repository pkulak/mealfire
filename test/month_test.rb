require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'

Bacon.summary_on_exit

describe 'a month' do
  it 'knows the first and last day' do
    month = MF::Month.new(2009, 7)
    month.first_day.should == Date.civil(2009, 6, 28)
    month.last_day.should == Date.civil(2009, 8, 1)
  end
end