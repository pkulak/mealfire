module MF
  module Model
    def self.included(base)
      base.extend(ClassMethods)  
    end
    
    module ClassMethods
      def updates_date_fields
        include MF::Model::UpdatesDateFields
      end
      
      def converts_ip_addresses
        include MF::Model::ConvertsIPAddresses
      end
    end
    
    module UpdatesDateFields
      def before_save
        return false if super == false
      
        if self.class.columns.include?(:updated_at)
          self.updated_at = Time.now
        end
      end

      def before_create
        return false if super == false
      
        if self.class.columns.include?(:created_at)
          self.created_at = Time.now
        end
      end
    end
    
    module ConvertsIPAddresses
      def ip=(ip)
        if (ip.is_a?(String))
          self[:ip] = MF::Math.ip2int(ip)
        else
          write_attribute(:ip, ip)
        end
      end


      def ip
        MF::Math.int2ip(self[:ip])
      end
    end
  end
end