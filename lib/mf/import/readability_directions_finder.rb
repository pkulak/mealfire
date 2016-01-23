require 'readability'

module MF::Import::ReadabilityDirectionsFinder
  def get_directions
    directions = try_get_directions

    if !directions || directions.strip == ""
      content = Readability::Document.new(@html, :clean_conditionally => true).content
      return content
    else
      return directions
    end
  end
end