module MF
  class Mailer
    # options: from, to, cc, subject, tag, html_body, text_body, reply_to
    def self.send_mail(options)
      options[:from] ||= {name: 'Mealfire Support', email: 'support@mealfire.com'}
      
      [:from, :to, :cc, :reply_to].each do |key|
        if options[key].is_a?(Hash)
          options[key] = "#{options[key][:name]} <#{options[key][:email]}>"
        elsif options[key].is_a?(AuthedUser)
          options[key] = "#{options[key].name} <#{options[key].email}>"
        end
      end
      
      # Camelize the keys.
      params = {}
      options.each{|k, v| params[k.to_s.camelize] = v}
      
      res = Net::HTTP.new('api.postmarkapp.com', 80).start do |http|
        req = Net::HTTP::Post.new('/email')
        req.add_field('Accept', 'application/json')
        req.add_field('Content-Type', 'application/json')
        req.add_field('X-Postmark-Server-Token', POSTMARK_KEY)
        req.body = params.to_json
        http.request(req)
      end
      
      if res.is_a?(Net::HTTPOK)
        return true
      else
        raise Exception.new("Email could not be sent")
      end
    end
  end
end