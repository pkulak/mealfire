class BookmarkletController < Controller
  layout do |path, wish|
    if path == 'loading' || path == 'general_import'
      'simple'
    elsif !request.xhr?
      'default'
    end
  end
  
  def import
    begin
      recipe = MF::Import::Importer.create_recipe(
        request[:url], request[:html].make_utf8, current_user)
    rescue Exception => e
      if RACK_ENV == 'development' && !e.is_a?(MF::Import::ImportException)
        raise e
      else
        if e.is_a?(MF::Import::ImportException)
          message = e.message
        else
          message = "Ooops! Looks like there was a problem importing that recipe. " +
            "Please make sure that you're on the main recipe page for a recipe " +
            "when you try to import it."
          
          log = ErrorLog.record_error(
            exception: e,
            type: 'IMPORT',
            user: current_user,
            request: request[:url])
          
          # Log the HTML in the filesystem.
          File.open(File.expand_path("../log/import_html/#{log.id}.html", File.dirname(__FILE__)), 'w') do |f|
            f << get_html
          end
        end
        
        flash[:notice] = ["Import Error", message, :important => true]
        redirect '/calendar'
      end
    end
    
    redirect "/recipe/edit/#{recipe.id}?from_import=true"
  end
  
  def general_import
    if request[:submit]         
      recipe = Recipe.create(
        name: request[:title].blank? ? "Untitled Recipe" : request[:title].make_utf8,
        user_id: current_user.id)
      
      recipe.add_ingredients(request[:ingredients].make_utf8)
      recipe.directions = request[:directions].make_utf8
      
      # Download the image.
      if request[:photo]
        begin
          uri = URI.parse(request[:photo])
          data = nil
      
          resp = Net::HTTP.start(uri.host, uri.port) do |http|
            req = Net::HTTP::Get.new(uri.path)
            http.request(req)
          end

          if resp.kind_of?(Net::HTTPSuccess)
            recipe.set_image(resp.body)
          end
        rescue Exception => e
          ErrorLog.record_error(
            exception: e,
            type: 'BAD_IMAGE',
            user: current_user,
            request: request[:photo])
        end
      end
      
      recipe.save
      
      respond render_file('view/bookmarklet/done.rhtml', recipe: recipe)
    else
      @photos = []
    
      request.params.each do |key, val|
        if key =~ /img_/
          @photos << val
        end
      end
    end
  end
end
