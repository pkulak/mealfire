module Sequel
  module Plugins
    module Json
      module InstanceMethods
        def to_hash
          data = {}
          final_serialize_attrs.uniq.each do |attr|
            if proc = self.class.procs[attr]
              value = proc.call(self)
            else
              value = self.send(attr)
            end
            
            if self.class.associations.include? attr
              # This is an association; apply included_attrs.
              if value.nil?
                data[attr] = nil
              elsif value.kind_of? Array
                # Insert models for association.
                data[attr] = value.collect do |e|
                  e.being_included = true
                  e.to_hash
                end
              elsif value.kind_of? Hash
                data[attr] = value
              elsif Sequel::Plugins::Serialize::InstanceMethods === value
                # Insert model data only
                value.being_included = true
                data[attr] = value.to_hash
              else
                # Should never happen
                raise RuntimeError.new("unknown type of value #{value.inspect} for association #{attr} on #{self.class}")
              end
            else
              # This is an ordinary value; insert directly.
              data[attr] = value
            end
          end
          data
        end

        # Returns a JSON document for this object.
        def to_json(*a)
          to_hash.to_json(*a)
        end
      end
    end
  end
end
