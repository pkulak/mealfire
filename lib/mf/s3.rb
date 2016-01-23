module MF
  class S3
    include AWS::S3
    include Magick
    
    Base.establish_connection!(
      :access_key_id     => AWS_ACCESS_KEY,
      :secret_access_key => AWS_SECRET_KEY
    )
    
    def self.upload_image(src, redirects = 3)
      if redirects < 0
        raise "Too many redirects"
      end
              
      # Grab the image.
      uri = URI.parse(src)
      data = nil
    
      Net::HTTP.start(uri.host, uri.port) do |http|
        resp = http.get(uri.path)
        
        if resp.kind_of?(Net::HTTPRedirection)
          return MF::S3.upload_image(resp['location'], redirects - 1)
        end
        
        data = resp.body
      end
      
      new_name = get_hash(data) + '.jpg'
      MF::S3.upload(new_name, data, 'image/jpeg')
      
      return "http://static.mealfire.com/#{new_name}"
    end
    
    def self.get_hash(data)
      hash = Digest::SHA1.new
      hash << data
      return hash.to_s
    end
    
    # Fill 48 x 48
    # Fill 100 x 100
    # Fit 250 x 250
    # Fit 640 x 480
    #
    # Everything before and including recipe 457 has a 100 icon that's
    # actually 75x75
    def self.upload_versions(data, hash)
      img = Image.from_blob(data).first
      
      v_48 = img.resize_to_fill(48, 48)
      v_100 = img.resize_to_fill(100, 100)
      
      if img.columns > 250 || img.rows > 250
        v_250 = img.resize_to_fit(250, 250)
      else
        v_250 = img
      end
      
      if img.columns > 640 || img.rows > 480
        v_640 = img.resize_to_fit(640, 480)
      else
        v_640 = img
      end
      
      [v_48, v_100, v_250, v_640].each{|i| i.format = 'JPEG'}
      
      upload(hash + "_48.jpeg", v_48.to_blob, 'image/jpeg')
      upload(hash + "_100.jpeg", v_100.to_blob, 'image/jpeg')
      upload(hash + "_250.jpeg", v_250.to_blob, 'image/jpeg')
      upload(hash + "_640.jpeg", v_640.to_blob, 'image/jpeg')
    end
    
    # Just used to create the new "thumbnail" size.
    def self.create_48_filesize
      Recipe.all.each do |r|
        next unless r.has_image
        
        # Grab the medium image (easy since it's public).
        uri = URI.parse(r.image_url(:medium))
        temp_file = Tempfile.new('random')

        Net::HTTP.start(uri.host, uri.port) do |http|
          resp = http.get(uri.path)

          open(temp_file.path, "wb") do |file|
            file.write(resp.body)
          end
        end
        
        img = Image::read(temp_file.path).first
        v_48 = img.resize_to_fill(48, 48)
        v_48.format = 'JPEG'
        upload(r.image_hash + '_48.jpeg', v_48.to_blob, 'image/jpeg')
        puts "Uploaded #{r.name}"
      end
    end
    
    def self.upload(file_name, file, content_type)
      S3Object.store(file_name, file, 'static.mealfire.com',
        :content_type => content_type,
        :access => :public_read)
    end
  end
end
