module MF::Import
  class MicroformatImporter < MF::Import::Importer
    include IngredientFinder
    include ReadabilityDirectionsFinder
    
    # We don't want to deal with the whole document.
    def initialize(html, doc)
      super
      @doc = @doc.at('.hrecipe, .hRecipe')
    end
    
    def get_title
      @doc.at('.fn').inner_text.strip
    end
    
    def get_image_url
      el = @doc.at('.photo')
      
      if el
        el['src']
      else
        false
      end
    end
    
    def get_ingredient_groups_with_depth(depth)
      # Find the parent of all the ingredients.
      parent = MF::Import::Importer.nearest_common_ancestor(@doc.search('.ingredient'), depth)
      groups = []
      
      return [] unless parent
      
      # Run through assuming that anything not an ingredient is a header.
      parent.traverse do |el|
        # Passing a parameter to ancestors is _horribly_ slow.
        skip = false
        
        el.ancestors.each do |a|
          if a['class'] && a['class'] =~ /( |^)ingredient( |$)/
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
        elsif el.name != 'text' && el['class'] =~ /( |^)ingredient( |$)/
          if groups.length == 0
            groups << {name: '', ingredients: []}
          end
          
          groups.last[:ingredients] << el.text.strip
        end
      end
      
      return MF::Import::Importer.prepare_groups(groups)
    end
    
    def try_get_directions
      directions = @doc.at('.instructions').to_s
      other = []
      
      if el = @doc.at('.prepTime')
        other << ["Prep Time", el.text]
      end
      
      if el = @doc.at('.cookTime')
        other << ["Cook Time", el.text]
      end
      
      if el = @doc.at('.duration')
        other << ["Total Time", el.text]
      end
      
      if el = @doc.at('.yield')
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
      return doc.at('.hrecipe, .hRecipe')
    end
  end
end