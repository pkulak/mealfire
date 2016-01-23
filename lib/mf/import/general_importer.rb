module MF::Import  
  class GeneralImporter
    include Magick
    
    def initialize(url, html = nil)
      if html
        @doc = Nokogiri::HTML(html)
      else
        @doc = Nokogiri::HTML(open(url))
      end
      
      @url = url
    end
    
    def find_photos
      root = URI.parse(@url)
      
      # Find the urls.
      image_urls = @doc.search('img').collect do |i|
        next unless i['src']
        
        url = URI.parse(CGI.unescapeHTML(i['src'])) rescue next
        
        if url.relative?
          if url.path =~ /^\//
            'http://' + root.host + url.path
          else
            'http://' + root.host + '/' + root.path.split('/')[0...-1].join('/') + url.path
          end
        else
          url.to_s
        end
      end
      
      image_urls.uniq!.compact!
      
      threads = []
      
      # Grab the data.
      image_urls.each do |url|
        threads << Thread.new(url) do |u|
          uri = URI.parse(u)
          
          def u.image; @image; end
          def u.image=(val); @image = val; end
          
          Net::HTTP.start(uri.host, uri.port) do |http|
            resp = http.get(uri.path)
            
            if resp.kind_of?(Net::HTTPSuccess)
              u.instance_variable_set(:@image, resp.body)
            end
          end
        end
      end
      
      threads.each{|t| t.join}
      
      # Turn them into actual images.
      image_urls.each do |u|
        if u.image
          u.image = Image.from_blob(u.image).first
        end
      end
            
      # Reject the ones that we don't like.
      image_urls.reject! do |u|
        image = u.image
        
        if !image
          true
        elsif image.columns < 100 || image.rows < 100
          true
        elsif (image.columns / image.rows) > 2 || (image.rows / image.columns) > 2
          true
        else
          false
        end
      end
      
      # Sort by size
      image_urls.sort! do |lhs, rhs|
        rhs.image.columns * rhs.image.rows <=> lhs.image.columns * lhs.image.rows
      end
      
      image_urls
    end
  end
end