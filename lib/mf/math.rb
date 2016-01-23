module MF
  class Math
    unless defined?(FRACTIONS)
      ALL_FRACTIONS = [
        [0, 1, '1'],
        [1.0, 8.0, '&#8539;', '&#x215B;', "\u215B"],
        [3.0, 8.0, '&#8540;', '&#x215C;', "\u215C"],
        [5.0, 8.0, '&#8541;', '&#x215D;', "\u215D"],
        [7.0, 8.0, '&#8542;', '&#x215E;', "\u215E"],
        [1.0, 6.0, '&#8537;', '&#x2159;', "\u2159"],
        [5.0, 6.0, '&#8538;', '&#x215A;', "\u215A"],
        [1.0, 5.0, '&#8533;', '&#x2155;', "\u2155"],
        [2.0, 5.0, '&#8535;', '&#x2156;', "\u2156"],
        [3.0, 5.0, '&#8535;', '&#x2157;', "\u2157"],
        [4.0, 5.0, '&#8536;', '&#x2158;', "\u2158"],
        [1.0, 4.0, '&#188;', '&#xBC;', "\u00BC"],
        [3.0, 4.0, '&#190;', '&#xBE;', "\u00BE"],
        [1.0, 3.0, '&#8531;', '&#x2153;', "\u2153"],
        [2.0, 3.0, '&#8532;', '&#x2154;', "\u2154"],
        [1.0, 2.0, '&#189;', '&#xBD;', "\u00BD"],
        [1, 1, '1']]
      
      FRACTIONS =   [
        [0, 1, '1'],
        [1.0, 4.0, '&#188;'],
        [3.0, 4.0, '&#190;'],
        [1.0, 3.0, '&#8531;'],
        [2.0, 3.0, '&#8532;'],
        [1.0, 2.0, '&#189;'],
        [1, 1, '1']]
    end
    
    def self.simple_fraction?(fraction)
      return true if fraction.is_a?(Integer)
      
      FRACTIONS.each do |f|
        if f[0] == fraction[1] && f[1] == fraction[2]
          return true
        end
      end
      
      return false
    end
    
    def self.random_string(length)
      o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map{|i| i.to_a}.flatten;  
      (0...length).map{o[rand(o.length)]}.join;
    end
    
    # Converts an IP string to integer  
	  def self.ip2int(ip)
	    return ip unless ip.is_a?(String)
	    return 0 unless ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
	
	    v = ip.split('.').collect { |i| i.to_i }  
	    return (v[0] << 24) | (v[1] << 16) | (v[2] << 8 ) | (v[3]) 
	  end  
	
	  # Converts an integer to IP string
	  def self.int2ip(int)  
	    tmp = int.to_i  
	    parts = []  
	
	    3.times do |i|  
	      tmp = tmp / 256.0  
	      parts << (256 * (tmp - tmp.to_i)).to_i  
	    end  
	
	    parts << tmp.to_i  
	    parts.reverse.join('.')  
	  end
	  
	  def self.fraction_to_float(fraction)
	    return fraction if fraction.is_a?(Integer)
      fraction[0] + fraction[1].to_f / fraction[2].to_f
    end
    
    def self.number_to_fraction(n, options = {})
      int_part = n.to_i
      frac_part = n - int_part
      fraction = get_fraction(frac_part, options)
      
      if [0,1].include?(fraction[0] / fraction[1])
        return int_part + fraction[0] / fraction[1]
      else
        return [int_part, fraction[0].to_i, fraction[1].to_i]
      end
    end

    # 0 <= dec >= 1
    def self.get_fraction(dec, options = {})
      least_index = nil
      least_value = 1
      i = 0
      
      fractions = options[:all_fractions] ? ALL_FRACTIONS : FRACTIONS

      fractions.each do |f|
        new_least = (f[0] / f[1] - dec)
        
        if options[:ceiling]
          if new_least < -0.005
            new_least = 1
          else
            new_least = new_least.abs
          end
        elsif options[:floor]
          if new_least > 0.005
            new_least = 1
          else
            new_least = new_least.abs
          end
        else
          new_least = new_least.abs
        end

        if new_least < least_value
          least_value = new_least
          least_index = i
        end

        i += 1
      end

      return fractions[least_index]
    end
  end
end