module MF::Import
  class AllRecipesImporter < MF::Import::MicroformatImporter
    def get_image_url
      img = get_image_by_selector('img#ctl00_CenterColumnPlaceHolder_recipe_photoStuff_imgPhoto')
      
      if img && img !~ /\/29568.gif$/
        return img.sub('/small/', '/big/')
      else
        return false
      end
    end
    
    # These guys don't mark up anything but the title and ingredients.
    def get_directions      
      @doc.at('div.directions h3').remove()
      directions = @doc.at('div.directions').inner_html
      
      # Grab the nutritional information.
      if nutrition = @doc.at('p.nutritional-information')
        directions << %Q{<p style="margin-top:20px;">#{nutrition.inner_html}</p>}
      end
      
      # Grap prep times.
      if times = @doc.at('div.times')
        prep_times = []
        
        times.search('h5').each do |h5|
          value = h5.at('span').inner_text.strip
          h5.at('span').remove
          key = h5.inner_text.strip
          prep_times << "<div><strong>#{key}</strong> #{value}</div>"
        end
        
        directions << '<p>' + prep_times.join + '</p>'
      end
      
      # Get the yield.
      if servings = @doc.at('span.yield')
        directions << '<p>' + servings.inner_text.strip + '</p>'
      end
      
      return directions
    end
    
    def self.my_recipe?(url, doc)
      begin
        if URI.parse(url).host !~ /allrecipes\.com$/
          return false
        end
      rescue Exception
        return false
      end
      
      if url.downcase.include?('/weblink/')
        raise ImportException.new("AllRecipes web links are not supported.")
      end
      
      if url.downcase.include?('/howto/')
        raise ImportException.new("AllRecipes how-to guides are not supported.")
      end
      
      return true
    end
  end
end