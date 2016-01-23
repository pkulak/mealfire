class UserException < Exception
  attr_reader :heading
  
  def initialize(heading, message = nil)
    if message == nil
      super(heading)
      @heading = "Error"
    else
      super(message)
      @heading = heading
    end
  end
  
  def self.missing(field_name)
    article = %w(a e i o u).include?(field_name[0].downcase) ? 'an' : 'a'
    UserException.new("#{field_name} Required", "Please enter #{article} #{field_name.downcase}.")
  end
  
  def to_a
    [@heading, self.message]
  end
end

class RecipeViewException < Exception
  attr_accessor :recipe
  
  def initialize(recipe)
    self.recipe = recipe
  end
end

class ImportedRecipeViewException < RecipeViewException; end
class PrivateRecipeViewException < RecipeViewException; end

class ApiException < Exception; end

class Time
  def to_date
    Date.civil(year, month, day)
  end
  
  def to_json(*a)
    "\"#{iso8601}\""
  end
end

class String
  def blank?
    return self.strip.length == 0
  end
  
  def required
    if self.blank?
      nil.required
    else
      return self
    end
  end
  
  def make_utf8
    # This is my awesome check for Latin1
    isLatin1 = false

    begin
      self.force_encoding('UTF-8').gsub(/s/, '')
    rescue Exception => e
      # It could be anything else, technically, but this is really just an
      # IE check.
      isLatin1 = true
    end
    
    if isLatin1
      return self.force_encoding('ISO-8859-1').encode('UTF-8')
    else
      return self.force_encoding('UTF-8')
    end
  end
end

class NilClass
  def blank?
    return true
  end
  
  def required
    raise UserException.new("Record Not Found",
      "The record you've requested could not be found. This is usually because " +
      "you're a search engine (which you're not if you're reading this) or " +
      "because what you're looking for no longer exists.")
  end
end

class Array
  def first_half
    self[0...(self.length / 2.0).ceil]
  end
  
  def last_half
    self[(self.length / 2.0).ceil..-1]
  end
  
  def sort_by_ids(ids)
    self.sort! do |lhs, rhs|
      l_index = ids.index(lhs.id) || (self.index(lhs) + ids.length)
      r_index = ids.index(rhs.id) || (self.index(rhs) + ids.length)
      l_index <=> r_index
    end
  end
end

class Object
  # The hidden singleton lurks behind everyone
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end

  # Adds methods to a metaclass
  def meta_def name, &blk
   meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def name, &blk
   class_eval { define_method name, &blk }
  end
end

class Hash
  def to_query
    self.collect{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join('&')
  end
end