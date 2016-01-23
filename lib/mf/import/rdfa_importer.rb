module MF::Import
  class RdfaImporter < MF::Import::Importer
    include IngredientFinder
    include ReadabilityDirectionsFinder
    
    # We don't want to deal with the whole document.
    def initialize(html, doc)
      super
      @doc = @doc.at('*[typeof="v:Recipe"]')
    end
    
    def get_title
      @doc.at('*[property="v:name"]').inner_text.strip
    end
    
    def get_image_url
      el = @doc.at('*[property="v:photo"]')
      
      if el
        el['src']
      else
        false
      end
    end
    
    def get_ingredient_groups_with_depth(depth)
      # Find the parent of all the ingredients.
      parent = MF::Import::Importer.nearest_common_ancestor(@doc.search('*[typeof="v:Ingredient"]'), depth)
      groups = []
      
      return [] unless parent
      
      # Run through assuming that anything not an ingredient is a header.
      parent.traverse do |el|
        # Passing a parameter to ancestors is _horribly_ slow.
        skip = false
        
        el.ancestors.each do |a|
          if a['typeof'] && a['typeof'] == 'v:Ingredient'
            skip = true
            break
          end
        end
        
        next if skip
                      
        # It's a group, or part of it.
        if el.name == 'text' && el.text.strip != ""
          if groups.length == 0 || groups.last[:ingredients].length > 0
            groups << {name: el.text.strip, ingredients: []}
          else
            groups.last[:name] << el.text.strip
          end
        elsif el.name != 'text' && el['typeof'] == 'v:Ingredient'
          if groups.length == 0
            groups << {name: '', ingredients: []}
          end
          
          groups.last[:ingredients] << el.text.strip
        end
      end
      
      return MF::Import::Importer.prepare_groups(groups)
    end
    
    def try_get_directions
      directions = @doc.at('*[property="v:instructions"]').to_s
      other = []
      
      if el = @doc.at('*[property="v:prepTime"]')
        other << ["Prep Time", el.text]
      end
      
      if el = @doc.at('*[property="v:cookTime"]')
        other << ["Cook Time", el.text]
      end
      
      if el = @doc.at('*[property="v:totalTime"]')
        other << ["Total Time", el.text]
      end
      
      if el = @doc.at('*[property="v:yield"]')
        other << ["Yield", el.text]
      end
      
      if other.length > 0
        ret = directions
        ret += %Q{<table style="margin-top:15px;">}
        
        other.each do |o|
          ret += %Q{<tr>} +
                   %Q{<td style="font-weight:bold;padding-right:10px;vertical-align:top;">#{o[0]}:</td>} +
                   %Q{<td>#{o[1]}</td>} + 
                 %Q{</tr>}
        end
        
        return ret + %Q{</table>}
      end
      
      return directions
    end
    
    def self.my_recipe?(url, doc)
      return doc.at('*[typeof="v:Recipe"]')
    end
  end
end