class ErrorLog < Sequel::Model(:error_logs)
  plugin :serialization
  serialize_attributes :json, :user
   
  # Options
  #   :type, :user, :exception, :request
  def self.record_error(options)
    if options[:user]
      user = options[:user].authed? ? options[:user].authed_user : options[:user]
    else
      user = nil
    end
    
    if options[:exception]
      error = options[:exception].message
      backtrace = options[:exception].backtrace ? 
        options[:exception].backtrace.join("\n") :
        nil
    else
      error = nil
      backtrace = nil
    end
    
    if options[:request]
      if options[:request].respond_to?(:params)
        request = options[:request].params
        request['user_agent'] = options[:request].env['HTTP_USER_AGENT']
        request['uri'] = options[:request].env['REQUEST_URI']
      else
        request = options[:request]
      end
    else
      request = nil
    end

    ErrorLog.create(
      type: options[:type],
      error: error,
      user: user ? user.values : nil,
      request: request.inspect,
      stack_trace: backtrace,
      created_at: Time.now)
  rescue Exception => e
    # Try again!
    ErrorLog.record_error(type: 'ERROR_ERROR', exception: e)
  end
  
  def uri
    if request =~ /"uri"=>"(.+?)"/
      $1
    else
      nil
    end
  end
end