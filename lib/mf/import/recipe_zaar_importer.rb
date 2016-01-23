module MF::Import
  class RecipeZaarImporter < MF::Import::MicroformatImporter    
    def get_image_url
      if url = get_image_by_selector('img.photo')
        return url.sub('/small/', '/large/')
      else
        return false
      end
    end
    
    def get_directions
      directions = @doc.at('span.instructions ol')
      
      # Yank the numbers they add in.
      directions.search('div.num').each do |el|
        el.remove
      end
      
      directions.to_s
    end
    
    def self.my_recipe?(url, doc)
      return check_host(url, 'food.com')
    end
  end
end