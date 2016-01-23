module Sequel
  module Plugins
    module Serialize
      # Terms
      #
      # "Attribute" means a field on a model which we expose to the API.
      # All attributes are provided as instance methods, which are called
      # during serialization.
      #
      # "Column" means a column in the database.
      #
      # "Association" means a Sequel association to another model or list of
      # models.
      #
      # Attributes can depend on any number of columns or associations. These
      # are selected or eager-loaded by api_filter.
      
      module DatasetMethods
        # Validates that params include only known keys, and processes the
        # params in preparation for other filtering methods. Does modify params!
        def api_validate(params)
          # Check for params sanity.
          known_keys = [
            'token',
            'include',
            'limit',
            'offset',
            'per_page',
            'page',
            'sort',
            'order'
          ]

          unknown_keys = params.keys - known_keys
          unless unknown_keys.empty?
            raise ApiException, "unknown parameters (#{unknown_keys.join(', ')})"
          end
          
          if params['include']
            params['include'] = MF::API::IncludeNode.from_string(params['include'])
          end

          self
        end

        # Adds columns and associations for attributes.
        def api_include(params)
          # Which columns must we select?
          select = []
          # Which associations must we eager-load?
          eagers = []
          
          model.default_attrs.each do |attr|
            select += model.attr_columns[attr.to_s]
            eagers += model.attr_associations[attr.to_s]
          end
          
          if params['include']
            select += MF::API::IncludeNode.build_select_list(params['include'], model)
            eagers += MF::API::IncludeNode.build_eager_graph(params['include'], model)
          end
                    
          # Don't eager load more than once. :)
          eagers.uniq!
          
          # Also select columns which associations may need to operate.
          eagers.each do |eager|
            # Add the primary key on this table needed to access everything.
            if eager.is_a?(Hash)
              ref = model.association_reflection(eager.keys.first.to_sym)
            else
              ref = model.association_reflection(eager)
            end
            
            case ref[:type]
            when :one_to_many
              select << ref[:primary_key] if ref[:primary_key]
            when :many_to_one
              select << ref[:key] if ref[:key]
            when :many_to_many
              select << ref[:left_primary_key] if ref[:left_primary_key]
            when :many_through_many
              select << ref[:left_primary_key] if ref[:left_primary_key]
            end
          end

          # Ensure we always select critical columns.
          select += model.key_columns
          
          # Don't select more than once
          select.uniq!
         
          # Modify a copy of this dataset.
          dataset = self.clone

          # Select columns
          if dataset.opts[:select] and
             dataset.opts[:select].size == 1 and 
             dataset.opts[:select].first.kind_of? Sequel::SQL::ColumnAll
            # This dataset is selecting ALL elements; drop the select and
            # replace it with our explicit selection.
            dataset.opts[:select] = select
          else
            # The dataset may have no select() columns -or- a number of explicit
            # selections; we will merge our own.
            dataset = dataset.select_more *select
          end

          # Eager loading
          dataset = dataset.eager(*eagers) unless eagers.empty?

          # Ensure we use the first table source as the qualifier for all
          # unqualified identifiers.
          dataset = dataset.qualify_to_first_source
          
          dataset
        end

        # Limit results by 'limit' and 'per_page'
        def api_limit(params)
          dataset = self

          if num = params['limit'] || params['per_page']
            i = num.to_i
            if num =~ /[^\d]/
              raise ApiException.new("invalid limit (#{num}) is not an integer")
            elsif i > model.maximum_limit
              raise ApiException.new("limit (#{i}) is higher than the maximum #{model.maximum_limit}")
            else
              dataset = dataset.limit(i)
            end
          else
            # Apply the default for limits if none is set.
            dataset.opts[:limit] ||= model.default_limit
          end

          dataset
        end
        
        # Sorts the dataset according to sort and order parameters.
        def api_sort(params)
          dataset = self.clone

          # Sort attribute
          if sort = params['sort']
            if model.attr_orders.include?(sort.to_sym)
              dataset = dataset.order sort.to_sym
            else
              raise ApiException.new("invalid sort attribute (#{sort})")
            end
          elsif dataset.opts[:order].nil?
            # Order by ID.
            dataset = dataset.order(:"#{model.table_name}__id")
          end
         
          # Sort order
          if dir = params['order']
            order = dataset.opts[:order].map do |term|
              if dir == 'asc'
                if term.kind_of? Sequel::SQL::OrderedExpression
                  # This is already ordered; modify the direction
                  term.expression.asc
                else
                  term.asc
                end
              elsif dir == 'desc'
                if term.kind_of? Sequel::SQL::OrderedExpression
                  # This is already ordered; modify the direction
                  term.expression.desc
                else
                  term.desc
                end
              else
                raise ApiException, "invalid order (#{params['order']}) is not 'asc' or 'desc'"
              end
            end
            # Apply order
            dataset = dataset.order(*order)
          end

          dataset
        end

        # Offset results by 'offset' and 'page'
        def api_offset(params)
          dataset = self

          # Offset results
          if num = params['offset']
            i = num.to_i
            if num =~ /[^\d]/
              raise ApiException.new("invalid offset (#{num}) is not an integer")
            else
              dataset.opts[:offset] = i
            end
          elsif num = params['page']
            i = num.to_i
            if num =~ /[^\d]/
              raise ApiException.new("invalid page (#{num}) is not an integer")
            elsif i <= 0
              raise ApiException.new("invalid page (#{num}) is less than 1")
            else
              dataset.opts[:offset] = (i - 1) * dataset.opts[:limit]
            end
          end

          dataset
        end

        # Use parameters to filter the dataset and return all rows.
        def api_filter(params, options = {})
          new_params = {}
          params.each{|param, value| new_params[param.to_s] = value}          
          params = new_params

          api_validate params
          
          skip = Proc.new do |key|
            options[:only_filter] && !options[:only_filter].include?(key)
          end
          
          dataset = self
          dataset = dataset.api_include params    unless skip.call(:include)
          dataset = dataset.api_sort params       unless skip.call(:sort)
          dataset = dataset.api_limit params      unless skip.call(:limit)
          dataset = dataset.api_offset params     unless skip.call(:offset)

          # Prepare the records for serialization
          records = dataset.all

          if params['include'] && !skip.call(:include)
            records.each do |record|
              MF::API::IncludeNode.serialize_attrs(record, params['include'], options[:proc])
            end
          end
          
          records
        end
      end

      module ClassMethods
        # Like attr(), but creates a default association instead of a default
        # column.
        def association_attr(name, params = {})
          defaults = {
            :columns => [],
            :associations => [name],
            :default => false,
            :include => false
          }
          
          ref = association_reflection(name)
          if ref
            if ref[:type] == :many_to_one
              # Add columns
              defaults[:columns] << ref[:key]
            else
              # Add association_count methods.
              meth = "#{name}_count".to_sym
              dataset = "#{name}_dataset".to_sym
              define_method(meth) do
                send(dataset).unlimited.count
              end
              
              # Add attribute for association_count
              self.attr meth, :columns => [] unless @attrs.include? meth
            end
          else
            raise RuntimeError, "Missing association #{name} for #{self}"
          end
            
          params = defaults.merge params

          self.attr(name, params)
        end


        # Metaprogramming method for specifying attributes. Parameters are:
        #   :columns => An array of SQL columns this attribute depends on.
        #   :associations => An array of Sequel associations for this class
        #     that should be eager-loaded.
        #   :default => Whether this attribute is loaded by default.
        #   :include => Whether this attribute is loaded on inclusion by other
        #     objects.
        def attr(name, params = {})
          defaults = {
            :columns => [],
            :associations => [],
            :default => false,
            :include => false,
            :order => nil,
            :proc => nil
          }
          if self.columns.include? name
            defaults[:columns] = [name]
          end

          params = defaults.merge params

          setup_attrs

          # Make sure columns are absolutely qualified, in case we do wacky
          # joins
          params[:columns].map! do |column|
            "#{self.table_name}__#{column}".to_sym
          end

          @attrs << name unless @attrs.include? name
          @attr_strings << name.to_s unless @attr_strings.include? name.to_s
          @attr_columns[name.to_s] = params[:columns]
          @attr_associations[name.to_s] = params[:associations]
          @default_attrs << name if params[:default] unless @default_attrs.include? name
          @include_attrs << name if params[:include] unless @include_attrs.include? name
          @procs[name] = params[:proc] if params[:proc]
          
          if params[:order]
            @attr_orders << name
          end
        end

        # Returns a list of attributes, as symbols.
        def attrs
          @attrs
        end

        # A hash which maps string attributes to arrays of symbols representing
        # the associations the attribute depends on.
        def attr_associations
          @attr_associations
        end
        
        # A hash which maps string attributes to arrays of symbols representing
        # the columns the attribute depends on.
        def attr_columns
          @attr_columns
        end

        # Map of attribute names (strings) to options for order()
        def attr_orders
          @attr_orders
        end

        # Same as attrs, but strings. A cache for efficiently selecting
        # valid attributes from parameter hashes without symbol table leakage.
        def attr_strings
          @attr_strings
        end

        # Symbols denoting attrs to load by default.
        def default_attrs
          @default_attrs
        end

        # How many results will we normally retrieve at a time?
        def default_limit
          10
        end

        # Symbols denoting attrs to include by default
        def include_attrs
          @include_attrs
        end
        
        # What columns must we *always* load?
        def key_columns
          @key_columns ||= ["#{self.table_name}__id".to_sym]
        end

        # How many results can you retrieve at a time?
        def maximum_limit
          100
        end

        # The string that is used when serializing this class for XML, JSON, etc.
        def serialized_name
          @serialized_name ||= to_s.demodulize.underscore
        end
        
        # A custom way to get a value for an attribute
        def procs
          @procs
        end

        def setup_attrs
          unless @attrs
            @attrs = []
            @attr_associations = {}
            @attr_columns = {}
            @attr_orders = []
            @attr_strings = []
            @default_attrs = []
            @include_attrs = []
            @procs = {}
          end
        end
      end

      module InstanceMethods
        def being_included=(value)
          @being_included = value
        end

        # True if this model is only being included instead of selected.
        def being_included?
          @being_included || false
        end

        # The final mixture of default attrs and user-specified attrs.
        def final_serialize_attrs    
          if being_included?
            self.class.include_attrs | serialize_attrs
          else
            self.class.default_attrs | serialize_attrs
          end
        end

        # Custom attributes to serialize.
        def serialize_attrs
          @serialize_attrs ||= []
        end

        def serialize_attrs=(attrs)
          @serialize_attrs = attrs.map do |attr|
            attr.to_sym
          end
        end
      end
    end
  end
end
