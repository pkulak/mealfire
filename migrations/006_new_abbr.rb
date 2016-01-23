class AddPasswordReset < Sequel::Migration
  def up
    unit = Unit.from_abbr('Tbsp')
    unit.abbreviation = unit.abbreviation + ',tbs,Tbs'
    unit.save
  end
end