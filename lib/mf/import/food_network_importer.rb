module MF::Import
  class FoodNetworkImporter < MF::Import::MicroformatImporter    
    def get_image_url
      img = get_image_by_selector('img.photo')
      
      if img
        return img.gsub(/med.jpg$/, 'lg.jpg')
      else
        return false
      end
    end
    
    def self.my_recipe?(url, doc)
      return URI.parse(url).host =~ /foodnetwork\.com$/ ? true : false
    rescue Exception
      return false
    end
  end
end