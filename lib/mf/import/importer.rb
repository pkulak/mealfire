require 'tempfile'

module MF::Import
  class ImportException < Exception; end
  
  class Importer    
    def initialize(html, doc)
      @html = html
      @doc = doc
      return self
    end
    
    def upload_images(element)
      element.search('img').each do |img|
        
        # Check for tracking images.
        if img['width'] == '1' && img['height'] == '1'
          img.remove
        else
          
          # Try to upload it, but if we can't, just yank it.
          begin
            img['src'] = MF::S3.upload_image(img['src'])
          rescue Exception
            img.remove
          end
        end
      end
    end
    
    def self.subclasses
      [
        AllRecipesImporter, EpicuriousImporter, RecipeZaarImporter,
        SimplyRecipesImporter, FoodNetworkImporter, WeightWatchersImporter,
        MicrodataImporter, MicroformatImporter, RdfaImporter
      ]
    end
    
    def self.create_recipe(url, html, user)        
      i = nil
      doc = Nokogiri::HTML(html)
      
      subclasses.each do |subclass|
        if subclass.my_recipe?(url, doc)
          i = subclass.new(html, doc)
          break
        end
      end
      
      if !i
        raise ImportException.new('That site cannot currently be automatically imported. Please grab the new bookmarklet <a href="/bookmarklet">here</a> to import from unsupported sites.')
      end
      
      recipe = Recipe.create(
        name: i.get_title,
        user_id: user.id,
        imported_from: url)
        
      groups = i.get_ingredient_groups
      
      if groups.length == 1 and groups[0][:ingredients].select{|i| i =~ /:$/}.length > 0
        groups = explode_group(groups[0])
      end
      
      groups.each do |g|
        new_group = recipe.add_ingredient_group(name: (g[:name] == nil ? nil : g[:name].strip))
        recipe.add_ingredients(g[:ingredients].collect{|i| prepare_ingredient(i)}, new_group)
      end
      
      # Grab the image.
      if image_url = i.get_image_url
        img_body = nil
        
        begin
          img_body = get_image(url, image_url)
        rescue Exception => e
          ErrorLog.record_error(
            exception: e,
            type: 'BAD_IMAGE',
            user: user,
            request: image_url)
        end
        
        recipe.set_image(img_body) if img_body
      end
            
      recipe.directions = i.get_directions
      
      i.get_tags.each do |t|
        recipe.add_tag(t)
      end
      
      recipe.save
    rescue Exception => e
      recipe.destroy if recipe
      raise e
    end
    
    # Splits a group based on ingredients that end in ":"
    def self.explode_group(group)
      groups = []
      
      group[:ingredients].each do |i|
        if i =~ /:$/
          groups << {:name => i[0...-1], :ingredients => []}
        else
          if groups.length == 0
            groups << {:name => nil, :ingredients => []}
          end
          
          groups.last[:ingredients] << i
        end
      end
      
      return groups
    end
    
    def self.get_image(url, image_url, retries = 3)
      image_url.strip!
      
      # No spaces in URLS!
      image_url.gsub!(' ', '%20')
      
      # Any other whitespace has got to go. Seriously, who the fuck puts a
      # newline in a URL? It's amazing that browsers have to put up with
      # this crap.
      image_url.gsub!(/\s/, '')
      
      # Convert to an absolute URI.
      uri = URI.parse(url)
      uri += image_url
    
      Net::HTTP.start(uri.host, uri.port) do |http|
        resp = http.get(uri.path)
        return resp.body
      end
    rescue Exception => e
      if retries > 0
        return get_image(url, image_url, retries - 1)
      else
        raise e
      end
    end
    
    def get_image_by_selector(selector, prefix = '')
      img = @doc.at(selector)

      if img
        return prefix + img['src'].gsub("\n", '').gsub('%0A', '')
      else
        return false
      end
    end
    
    def self.prepare_ingredient(i)
      i.gsub(/\s+/, ' ').strip
    end
    
    def self.prepare_groups(groups)
      # Yank those icky colons.
      groups.each {|grp| grp[:name].gsub!(/:$/, '') }
      
      # If the last group has no ingredients, get rid of it.
      if groups.last()[:ingredients].length == 0
        groups = groups[0...-1]
      end
      
      # Get rid of "Ingredients" at the front of the first group.
      groups.first()[:name].gsub!(/^Ingredients/, '')
      
      groups
    end
    
    def get_tags
      []
    end
    
    def self.check_host(url, host)
      url_host = URI.parse(url).host
      
      if url_host == host
        return true
      end
      
      if url_host =~ /\.#{Regexp.escape(host)}$/
        return true
      end
      
      return false
    rescue
      return false
    end
    
    def self.nearest_common_ancestor(elements, depth)      
      nca = Proc.new do |a, b|
        ret = nil
        
        (Nokogiri::XML::NodeSet.new(a.document, [a]) + a.ancestors[0..depth]).each do |a_parent|
          b.ancestors[0..depth].each do |b_parent|
            if a_parent == b_parent
              ret = b_parent
              break
            end
            
            break if ret
          end
        end
        
        ret
      end
      
      if elements.length < 2
        return nil
      end
      
      if elements.length == 2
        return nca.call(elements[0], elements[1])
      end
      
      ca = nca.call(elements[0], elements[1])
      
      # If there are no common ancestors close enough, discard the tree
      if !ca
        return nearest_common_ancestor(elements[2..-1], depth)
      end
      
      return nearest_common_ancestor([ca] + elements[2..-1], depth)
    end
  end
end
