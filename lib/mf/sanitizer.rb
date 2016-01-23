module MF
  class Sanitizer
    unless defined?(ALLOWED_TAGS)
      ALLOWED_TAGS = %W[p br a b strong img ol ul li div span h1 h2 h3 i em dl dd dt table tr td th tbody thead]
      STRIPPED_TAGS = %W[blockquote]
      ALLOWED_ATTRS = {
        'src' => 'img',
        'href' => 'a'
      }
      DISALLOWED_STYLES = %W[position left top bottom right]
    end
    
    def self.compact_html(html)
      html.gsub(/\n */, '').gsub(/ +/, ' ')
    end
    
    def self.sanitize(text)
      doc = Nokogiri::HTML(text)
      
      if doc.at('body')
        doc.at('body').traverse do |n|
          Sanitizer.sanitize_node(n) unless n.name == 'body'
        end
        
        return doc.at('body').inner_html
      else 
        return ""
      end
    end
    
    def self.sanitize_node(node)
      if STRIPPED_TAGS.include?(node.name)
        node.after(node.children)
        node.unlink
      elsif !ALLOWED_TAGS.include?(node.name) && node.name != 'text'
        node.unlink
      else
        node.attributes.each do |key, val|
          if key == 'style'
            style = sanitize_style(val.to_s)
            node.set_attribute('style', style)
          elsif key.downcase == 'class'
            # Keep the attribute
          elsif !ALLOWED_ATTRS.has_key?(key) || ALLOWED_ATTRS[key] != node.name ||
              val.to_s.downcase.include?('javascript:')
            node.remove_attribute(key)
          end
        end
        
        node.children.each{|n| Sanitizer.sanitize_node(n)}
      end
    end
    
    def self.sanitize_style(style)
      styles = style.split(';').collect{|s| s.split(':').collect{|t| t.strip.downcase}};
      new_style = ''

      styles.each do |s|
        if !DISALLOWED_STYLES.include?(s.first)
          new_style << s.first + ":" + s.last + ';'
        end
      end
      
      return new_style
    end
  end
end