module MF::Import
  class EpicuriousImporter < MF::Import::Importer
    def get_title
      @doc.at('#headline h1').inner_text.strip
    end
    
    def get_image_url
      img = get_image_by_selector('#recipe_thumb img', 'http://www.epicurious.com')

      if img
        return img.sub('_116.jpg', '.jpg')
      else
        return false
      end
    end
    
    def get_directions
      ret = ''
      
      summary_data = @doc.search('#recipe_summary p.summary_data')
      
      if summary_data
        ret << summary_data.collect{|sd| '<div>' + sd.inner_html + "</div>"}.join
        ret << '<br/>'
      end
      
      directions = @doc.at('#preparation')
      
      directions.search('h2').each do |h2|
        if h2.inner_text =~ /preparation/i
          h2.remove
        end
      end
      
      directions.search('a').each{|a| a.remove}
      
      ret << directions.inner_html
    end
    
    def get_ingredient_groups
      if @doc.search('#ingredients strong').length > 0
        return get_multiple_ingredient_groups
      end
      
      group = {name: '', ingredients: []}

      @doc.search('ul.ingredientsList')[0].search('li').each do |li|
        group[:ingredients] << li.inner_text
      end
      
      return [group]
    end
    
    def get_multiple_ingredient_groups
      groups = []
      
      @doc.at('#ingredients').traverse do |el|
        if el.name == 'strong'
          groups << {name: el.inner_text.strip.sub(/:$/, ''), ingredients: []}
        elsif el.name == 'li'
          if !groups.last
            groups << {name: nil, ingredients: []}
          end
          
          groups.last[:ingredients] << el.inner_text
        end
      end
      
      return groups
    end
    
    def self.my_recipe?(url, doc)
      return URI.parse(url).host =~ /epicurious\.com$/ ? true : false
    rescue Exception
      return false
    end
  end
end