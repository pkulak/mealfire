module MF::Import
  class WeightWatchersImporter < MF::Import::Importer
    def get_title
      @doc.at('span.recipe_title, span#lblRecipeTitle, span.article_title').inner_text.strip
    end
    
    def get_image_url
      url = get_image_url_internal
      
      if url.include?('Community_Default_Recipe_pic.gif')
        return nil
      else
        return url
      end
    end
    
    def get_image_url_internal
      if img = get_image_by_selector('img#imgRecipeImage')
        return img
      else
        @doc.search('img').each do |img|
          if img['src'].include?('aka.weightwatchers.com/images/') &&
              img['src'].include?('/articles/')
            return img['src']
          end
        end
        
        return nil
      end
    end
    
    def get_directions
      # Check for a different format.
      if block = @doc.at('div.recipeblock')
        seen_directions = false
        directions = ''
        
        block.traverse do |el|
          if el.name == 'h3' && el.text == 'Instructions'
            seen_directions = true
          elsif el.name == 'ul' && seen_directions
            el.search('li').each do |li|
              directions << '<p>' + li.text + '</p>'
            end
            
            return directions
          end
        end
      end
      
      ret = ""
      seen_instructions = false
      seen_notes = false
      
      instructions = []
      notes = []
      
      if directions = @doc.at('div.recipe_int')
        directions.children.each do |child|
          if child.name == 'h4'
            if child.inner_text =~ /Instructions/
              seen_notes = false
              seen_instructions = true
            elsif child.inner_text =~ /Notes/
              seen_notes = true
              seen_instructions = false
            else
              seen_notes = seen_instructions = false
            end
          elsif child.name != 'br'
            if seen_instructions
              instructions << child
            elsif seen_notes
              notes << child
            end
          end
        end
      else
        instructions << @doc.at('#lblInstructions')
        notes << @doc.at('#lblNotes')
      end
      
      instructions.each do |i|
        ret << i.to_s
      end
      
      if notes.length > 0
        ret << "<h2>Notes</h2>"
        
        notes.each do |n|
          ret << n.to_s
        end
      end
      
      if info = @doc.search('#tableRecipe tr, #uctl_receipe_tableRecipe tr').last and info.at('td')
        ret << '<h2>Info</h2>'
        ret << '<p>' + info.at('td').inner_html + '</p>'
      else
        ret << '<h2>Info</h2>'
        ret << "<p><strong>Servings:</strong> #{@doc.at('#lblServings')}"
        ret << "<br><strong>Points:</strong> #{@doc.at('#lblPoints')}</p>"
      end
    end
  
    def get_ingredient_groups
      group = {name: '', ingredients: []}
      
      if ingredients = @doc.at('div.recipe_int table')
        ingredients.search('tr').each do |el|
          if td = el.search('td')[1]
            group[:ingredients] << td.inner_text
          end
        end
      elsif ingredients = @doc.at('#lblIngredients')
        ingredients.inner_html.split('<br>').each do |i|
          group[:ingredients] << i
        end
      else
        seen_ingredients = false
        @doc.at("div.recipeblock").traverse do |el|
          if el.name == 'h3' && el.text == 'Ingredients'
            seen_ingredients = true
          elsif el.name == 'ul' && seen_ingredients
            el.search('li').each do |li|
              group[:ingredients] << li.text
            end
            break
          end
        end
      end
    
      [group]
    end
    
    def get_tags
      if recipe_stats = @doc.at('#divRecipeStats')
        recipe_stats.traverse do |el|
          if el.name == 'td' && el.text.include?("Course:")
            return [el.at('span').text.strip.gsub(/e?s$/, '')]
          end
        end
      elsif box = @doc.at('#divRecipeBoxTop h1 span, #uctl_receipe_divRecipeBoxTop span, #lblCourse2')
        return [box.inner_text.strip.gsub(/e?s$/, '')]
      end
      
      return []
    end
  
    def self.my_recipe?(url, doc)
      if URI.parse(url).host =~ /weightwatchers\.com$/
        return true
      end
    
      return false
    rescue Exception
      return false
    end
  end
end