module MF::Import
  class SimplyRecipesImporter < MF::Import::MicroformatImporter
    # def get_title
    #   @doc.at('#recipe-callout h2').inner_text.gsub("Recipe", "").strip
    # end
    # 
    # def get_image_url
    #   get_image_by_selector('div.entry-photo img')
    # end
    
    def get_directions
      directions = ''
      
      if intro = @doc.at('#recipe-intronote p')
        directions << %Q{<p style="font-style:italic">#{intro.inner_html}</p>}
      end
      
      @doc.at('#recipe-method h3').remove
      
      method = @doc.at('#recipe-method')
      
      # We may have some images in here, and we don't want to hotlink.
      upload_images(method)
      
      # Apply the styles inline.
      method.search('img').each do |img|
        img['style'] = 'border: 1px solid #EFE7DA;padding: 2px;margin: 4px 0px 4px 6px;'
      end
      
      directions << method.inner_html
    end
    
    # def get_ingredient_groups
    #   groups = []
    #   ingredients = @doc.at('#recipe-ingredients')
    #   
    #   if !ingredients
    #     return []
    #   end
    #   
    #   ingredients.traverse do |el|
    #     if el.name == 'p'
    #       groups << {name: el.inner_text.strip, ingredients: []}
    #     elsif el.name == 'ul'
    #       if groups.length == 0
    #         groups << {name: nil, ingredients: []}
    #       end
    #       
    #       el.search('li').each do |li|
    #         groups.last[:ingredients] << li.inner_text
    #       end
    #     end
    #   end
    #   
    #   return groups
    # end
    
    def self.my_recipe?(url, doc)
      if URI.parse(url).host =~ /simplyrecipes\.com$/ ||
          URI.parse(url).host =~ /elise\.com$/
        return true
      end
      
      return false
    rescue Exception
      return false
    end
  end
end