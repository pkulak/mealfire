module Rack::Mealfire; end
class Rack::Mealfire::JSONP
  INVALID_MSG = 'Error: invalid or missing JSONP callback name. Callback must consist only of letters, numbers, and underscores.'
  INVALID_RESPONSE = [
    400, {
      'Content-Type' => 'text/plain',
      'Content-Length' => INVALID_MSG.size.to_s
    },
    [INVALID_MSG]
  ]

  # Intercepts requests for .jsonp and wraps them in JSONP callbacks.
  def initialize(app, options = {})
    @app = app
    @callback_param = options[:callback_param] || 'callback'
  end

  def call(env)
    request = Rack::Request.new(env)

    if env['PATH_INFO'] =~ /\.jsonp$/
      # JSONP request

      callback = request.params.delete(@callback_param)
      unless callback and callback =~ /^[a-z0-9_]+$/i
        # Invalid callback!
        return INVALID_RESPONSE
      end
    
      # Rewrite .jsonp to .json 
      env['PATH_INFO'].sub!(/\.jsonp$/, '.json')
      
      # Take note of the callback for later.
      env['mealfire.jsonp_callback'] = callback

      # We're a JSONP request. Rewrite the query string and delete the callback
      # parameter from the request.
      env['QUERY_STRING'] = env['QUERY_STRING'].split("&").delete_if{|param| param =~ /^(_|#{@callback_param})/}.join("&")

      # Call app
      status, headers, response = @app.call(env)
      
      # Pad response
      response = pad(callback, response)
      
      # Reset content-type (we're a script now, not JSON)
      headers['Content-Type'] = 'application/javascript; charset=utf-8'
      # Length has changed too, count the bytes
      content_length = 0
      response.first.each_byte{|b| content_length += 1}
      headers['Content-Length'] = content_length.to_s

      # Respond...
      [status, headers, response]
    elsif env['PATH_INFO'] =~ /\.js(on)?$/ && env['PATH_INFO'] !~ /^\/js\//
      status, headers, response = @app.call(env)
      headers['Content-Type'] = 'application/json; charset=utf-8'
      headers['Access-Control-Allow-Origin'] = 'http://localhost:8000'
      [status, headers, response]
    else
      # Fall straight through
      @app.call env 
    end
  end

  # Pads the response with the appropriate callback format according to the
  # JSON-P spec/requirements.
  #
  # The Rack response spec indicates that it should be enumerable. The method
  # of combining all of the data into a single string makes sense since JSON
  # is returned as a full string.
  #
  def pad(callback, response, body = "")
    response.each{ |s| body << s.to_s }
    ["#{callback}(#{body})"]
  end
end