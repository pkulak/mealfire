module MF
  class Month
    attr_reader :month, :year, :weeks, :first_day, :last_day, :controller
    
    def initialize(year, month, controller)
      @year = year
      @month = month
      @controller = controller
      @weeks = []
      
      first_of_the_month = Date.civil(year, month, 1)
      @first_day = first_of_the_month - first_of_the_month.wday
      
      days_to_display = Date.new(year, month, -1).day + first_of_the_month.wday
      
      if days_to_display > 35
        rows = 6
      elsif days_to_display < 29
        rows = 4
      else
        rows = 5
      end
      
      @last_day = @first_day + 7 * rows - 1
      day = @first_day.dup
      
      0.upto(rows - 1) do
        week = []
        @weeks << week
        
        0.upto(6) do
          week << MF::Day.new(day, self)
          day += 1
        end
      end
    end
    
    def render_day(day)
      weeks.flatten.select{|d| d == day}.first.render
    end
    
    def name
      Date::MONTHNAMES[@month]
    end
    
    def previous
      @previous ||= self.add(-1)
    end
    
    def next
      @next ||= self.add(1)
    end
    
    def fill_days(recipe_days, saved_lists)
      @weeks.each do |week|
        week.each do |day|
          recipe_days.select{|rd| day == rd.day}.each do |match|
            day.add_recipe_day(match)
          end
          
          saved_lists.select{|sl| day == sl.day(controller.current_user)}.each do |match|
            day.add_saved_list(match)
          end
        end
      end
    end
    
    def add(ammount)
      m = @month + ammount
      y = @year
      
      if m == 0
        y -= 1
        m = 12
      elsif m == 13
        y += 1
        m = 1
      end
            
      day = Date.civil(y, m, 1)
      Month.new(day.year, day.month, controller)
    end
    
    def day_in(day)
      day.month == @month && day.year == @year
    end
  end
  
  class Day         
    def initialize(day, month)
      @day = day
      @month = month
      @recipe_days = []
      @saved_lists = []
    end
    
    def ==(rhs)
      @day == rhs
    end
    
    def is_today?
      @day == @month.controller.current_user.adjust_time(Time.now).to_date
    end
    
    def add_recipe_day(day)
      @recipe_days << day
    end
    
    def add_saved_list(sl)
      @saved_lists << sl
    end
    
    def render
      recipe_string = ''
      
      @saved_lists.each do |sl|
        recipe_string << %Q{
          <div class="recipe_box saved_list">
            <img src="/images/gl_left.png" class="left"/>
            <div class="middle"><a href="/shop/show?saved_list=#{sl.id}">Grocery List</a><!--[if lt IE 7]><span>&nbsp;</span><![endif]--></div>
            <img src="/images/gl_right.png" class="right"/>
          </div>}
      end
      
      @recipe_days.sort{|lhs, rhs| lhs.order_by <=> rhs.order_by}.each do |day|
        side_dish = day.recipe.side_dish
        
        recipe_string << %Q{
          <div class="recipe_box in_calendar #{'side_dish_box' if side_dish}" id="day_#{day.id}">
            <img src="/images/#{side_dish ? 'sd' : 'rb'}_left.png" class="left"/>
            <div class="middle">#{day.recipe.name}</div>
            <img src="/images/#{side_dish ? 'sd' : 'rb'}_right.png" class="right"/>
          </div>}
      end
      
      total_boxes = @recipe_days.length + @saved_lists.length
      
      if total_boxes < 3
        0.upto(3 - total_boxes - 1) do
          recipe_string << %Q{<div class="spacer">&nbsp;</div>}
        end
      end
      
      row_id = "date-#{@day.year}_#{@day.month}_#{@day.mday}"
                  
      MF::Sanitizer.compact_html(%Q{
        <div id="#{row_id}" class="calendar_day #{'today' if is_today?} #{'not_this_month' if !@month.day_in(@day)} #{'day_with_recipes' if @recipe_days.length > 0}">
          <div class="day">
            #{Date::MONTHNAMES[@day.month] if @day.day == 1} #{@day.day}
          </div>
          <div class="rs">
            #{recipe_string}
          </div>
        </div>
        <script type="text/javascript">$(function(){setupCell($('##{row_id}'))});</script>
      })
    end
  end
end