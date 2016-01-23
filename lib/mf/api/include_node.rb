module MF::API
  class IncludeNode
    attr_accessor :name, :children
  
    def initialize(name)
      @name = name
      @children = []
    end
    
    def self.serialize_attrs(model, nodes, proc = nil)
      return unless model
      
      # Apply the block to the model, if it was given.
      proc.call(model) if proc
      
      return if nodes.length == 0
      
      nodes.each do |node|
        model.serialize_attrs << node.name.to_sym
        
        new_models = model.send(node.name.to_sym)
        new_models = [new_models] unless new_models.is_a?(Array)
        
        new_models.each do |new_model|
          self.serialize_attrs(new_model, node.children, proc)
        end
      end
    end
    
    def self.build_select_list(nodes, model)
      nodes.collect{|n| n.to_select_list(model)}.flatten.compact
    end
    
    def to_select_list(model)
      if (association = model.attr_columns[self.name]) && association.first
        return association.first
      elsif association = model.attr_associations[self.name]
        return nil
      else
        raise ApiException, "invalid attribute '#{self.name}' for include"
      end
    end
    
    def self.build_eager_graph(nodes, model)
      ret = nodes.collect do |node|
        node.to_eager_graph(model)
      end
      
      ret.compact
    end
    
    def to_eager_graph(model)
      if association = model.attr_associations[self.name]
        association = association.first
        if self.children.length == 0
          return association
        else
          new_model = Kernel.const_get(model.association_reflection(self.name.to_sym)[:class_name])
          new_children = self.children.collect{|c| c.to_eager_graph(new_model)}.compact
          new_children = new_children.first if new_children.length == 1
          return {association => new_children}
        end
      else
        # Just to check for errors.
        if !model.attr_columns[self.name]
          raise ApiException, "invalid attribute '#{self.name}' for include"
        end
      end
    end
    
    # Format "attr1,attr2[child1,child2]" etc
    def self.from_string(s)
      comma_split(s).collect do |node_string|
        split = bracket_split(node_string)
        if split.length == 2
          node = IncludeNode.new(split[0])
          node.children = IncludeNode.from_string(split[1])
        else
          node = IncludeNode.new(split[0])
        end
        
        node
      end
    end
    
    # Split on top-level commas
    def self.comma_split(s)
      bracket_depth = 0
      splits = []
      current = ''
      
      s.each_char do |c|
        if c == '['
          bracket_depth += 1
          current << c
        elsif c == ']'
          bracket_depth -= 1
          current << c
        elsif c == ',' && bracket_depth == 0
          splits << current
          current = ''
        else
          current << c
        end
      end
      
      if current != ''
        splits << current
      end
      
      splits
    end
    
    # Split on top-level brackets
    def self.bracket_split(s)
      if !s.include?('[')
        return [s]
      end
      
      car = ''
      cdr = ''
      bracket_depth = 0
      
      s.each_char do |c|
        if c == '['
          bracket_depth += 1
          cdr << c unless bracket_depth == 1
        elsif c == ']'
          bracket_depth -= 1
          cdr << c unless bracket_depth == 0
        else
          if bracket_depth == 0
            car << c
          else
            cdr << c
          end
        end
      end
      
      [car, cdr]
    end
  
    def to_s
      self.name
    end
  end
end