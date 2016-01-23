module MF
  class Paginator    
    def initialize(options)
      @current_page = options[:current_page]
      
      if options[:dataset]
        first_record = options[:per_page] * (@current_page - 1)
        @records = options[:dataset].limit(options[:per_page] + 1, first_record).all
      
        if @records.length > options[:per_page]
          @last_page = false
          @records = @records[0...-1]
        else
          @last_page = true
        end
      else
        @records = options[:records]
        @last_page = @records.length < options[:per_page] ||
          options[:per_page] * (@current_page - 1) + @records.length == options[:total]
      end
    end
    
    def first_page?
      @current_page == 1
    end
    
    def last_page?
      @last_page
    end
    
    def prev_page
      first_page? ? 1 : @current_page - 1
    end
    
    def next_page
      last_page? ? @current_page : @current_page + 1
    end
    
    def method_missing(sym, *args, &block)
      @records.send(sym, *args, &block)
    end
  end
  
  class EmptyPaginator
    def first_page?
      true
    end
    
    def last_page?
      true
    end
    
    def prev_page
      1
    end
    
    def next_page
      1
    end
    
    def method_missing(sym, *args, &block)
      [].send(sym, *args, &block)
    end
  end
end