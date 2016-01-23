class Unit < Sequel::Model(:units)
  plugin :serialize
  plugin :json
  
  many_to_one :lower_unit, :class => Unit
  many_to_one :upper_unit, :class => Unit
  
  # Serialization
  attr :abbr, :default => true, :include => true
  attr :name
  attr :si
  
  attr :type, :proc => Proc.new {|model|
    model.type == VOLUME ? 'volume' : 'mass'
  }
  
  unless defined?(VOLUME)
    VOLUME = 0
    MASS = 1
  end
  
  def self.[](abbr)
    self.from_abbr(abbr)
  end
  
  def self.from_abbr(abbr)
    res = self.cached_all.select{|u| u.abbr == abbr}
    res.length > 0 ? res[0] : nil
  end
  
  def abbr
    self.abbreviations.first
  end
  
  def abbreviations
    split = self.abbreviation.split(',')
    split.concat(split.collect{|abbr| abbr + '.'})
  end
  
  def self.cached_all
    @all ||= Unit.all
  end
  
  def self.conversions(type)
    cached_all.select do |u|
      u.type == type && 
        ['tsp', 'Tbsp', 'fl oz', 'cp', 'qt', 'gal', 'ml', 'l', 'oz', 'lb', 'g', 'kg'].include?(u.abbr)
    end
  end
  
  def self.add_data
    data = [
      ['teaspoon', 'tsp,t', 4.928],
      ['tablespoon', 'Tbsp,tbsp,T', 14.786],
      ['fluid ounce', 'fl oz', 29.573],
      ['cup', 'cp,C,c', 236.588],
      ['pint', 'pt', 473.176],
      ['quart', 'qt', 946.342],
      ['gallon', 'gal', 3785.412]
    ]
    
    data.each do |d|
      Unit.create(:name => d[0], :abbreviation => d[1], :type => Unit::VOLUME, :si => d[2])
    end
    
    data = [
      ['ounce', 'oz', 28.349],
      ['pound', 'lb,lbs', 453.592],
    ]
    
    data.each do |d|
      Unit.create(:name => d[0], :abbreviation => d[1], :type => Unit::MASS, :si => d[2])
    end
    
    # Set up our conversion bounds.
    cup = Unit.from_abbr('cp')
    cup.lower_bound = 0.25
    cup.lower_unit = Unit.from_abbr('Tbsp')
    cup.save
    
    tbsp = Unit.from_abbr('Tbsp')
    tbsp.upper_bound = 4
    tbsp.upper_unit = Unit.from_abbr('cp')
    tbsp.lower_bound = 0.334
    tbsp.lower_unit = Unit.from_abbr('tsp')
    tbsp.save
    
    tsp = Unit.from_abbr('tsp')
    tsp.upper_bound = 3
    tsp.upper_unit = Unit.from_abbr('Tbsp')
    tsp.save
    
    lb = Unit.from_abbr('lb')
    lb.lower_bound = 0.25
    lb.lower_unit = Unit.from_abbr('oz')
    lb.save
    
    oz = Unit.from_abbr('oz')
    oz.upper_bound = 16
    oz.upper_unit = Unit.from_abbr('lb')
    oz.save
  end
end
