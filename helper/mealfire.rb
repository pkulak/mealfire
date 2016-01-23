module Ramaze
  module Helper
    module Mealfire
      def bookmarklet_source
        %Q{javascript:#{"var%20mealfireHost='localhost:7000';" if RACK_ENV == 'development'}var%20mealfireVersion=2;function%20loadScript(scriptURL)%20{%20var%20scriptElem%20=%20document.createElement('SCRIPT');%20scriptElem.setAttribute('language',%20'JavaScript');%20scriptElem.setAttribute('src',%20scriptURL);%20document.body.appendChild(scriptElem);}var%20mealfireWindow=window.open('http://#{DOMAIN}/bookmarklet/loading','mealfireImport','toolbar=0,status=0,resizable=1,scrollbars=1,width=540,height=510');loadScript('http://#{DOMAIN}/js/bookmarklet.js?rand'+Math.random());void(0)}
      end
      
      def recipe_rating_html(recipe, user)
        return nil unless recipe.rating
        
        r = recipe.normalized_rating(user.min_rating, user.max_rating)
        
        class_name = if r < 0.1 then 'stars_0_0'
          elsif r < 0.1 then 'stars_0_5'
          elsif r < 0.2 then 'stars_1_0'
          elsif r < 0.3 then 'stars_1_5'
          elsif r < 0.4 then 'stars_2_0'
          elsif r < 0.5 then 'stars_2_5'
          elsif r < 0.6 then 'stars_3_0'
          elsif r < 0.7 then 'stars_3_5'
          elsif r < 0.8 then 'stars_4_0'
          elsif r < 0.9 then 'stars_4_5'
          else 'stars_5_0'
        end
        
        %Q{<div class="stars #{class_name}"></div>}
      end
      
      def show_banner
        if (ie_6? || ie_7?) && !session[:disable_browser_warning]
          @top_banner = render_file "view/banner/_browser_warning.rhtml"
        elsif !current_user.authed? && !session[:disable_warning]
          @top_banner = render_file "view/banner/_guest_warning.rhtml"
        elsif current_user.authed? && current_user.rate_recipes && day = current_user.recipe_day_to_rate
          @top_banner = render_file "view/banner/_rate_recipe.rhtml", day: day
        end
      end
      
      def ingredient_list(recipe, multiplier)
        s = %Q{<div id="ingredient_holder" style="margin-left:10px;"><ul>}
        
        recipe.ingredient_groups.each do |grp|
          if !grp.name.blank?
            s << %Q{<li><div class="ingredient_group">#{h grp.name}</div><ul>}
          end
          grp.ingredients.each do |i|
            s << %Q{<li itemprop="ingredient" itemscope itemtype="http://data-vocabulary.org/RecipeIngredient" class="ingredient">}
            s << ingredient_to_html(i, :html_fraction => true, :multiplier => multiplier)
            s << "</li>"
          end
          if !grp.name.blank?
            s << "</ul></li>"
          end
        end
        
        s << "</ul></div>"
      end
      
      def id_from_multi(multi)
        multi.split('_')[1]
      end
      
      def date_box(date)
        s = %q{<div class="date_box">}
        s << %Q{<div class="month">#{date.strftime('%b')}</div>}
        s << %q{<div class="day">}
        
        if date.year != Date.today.year
          s << date.strftime('%y')
        else
          s << date.day.to_s
        end
        
        s << '</div></div>'
      end
      
      def smart_date(time, show_time = false)
        return '' if time.nil?

        delta = Time.now - time
        if delta < 2.minutes
          "just now"
        elsif delta < 90.minutes
          sprintf "#{(delta.to_f / 60).round} mins ago"
        elsif delta < 4.days
         time_diff(time).sub(/about /,'') + " ago"
        else
          datetime_stamp(time, show_time)
        end
      end
      
      def datetime_stamp(t, show_time = false)
        if show_time
          hour = (t.hour % 12)
          hour = 12 if hour == 0

          sprintf "%s %d, %d %d:%02d%s", Time::RFC2822_MONTH_NAME[t.month-1], t.mday, t.year, hour, t.min, (t.hour <= 11 ? 'am' : 'pm')
        else
          sprintf "%s %d, %d", Time::RFC2822_MONTH_NAME[t.month-1], t.mday, t.year
        end
      end
      
      def format_date(dt, options = {})
        if options[:user]
          today = options[:user].adjust_time(Time.now).to_date
        else
          today = Date.today
        end
        
        return '' if !dt
        return 'today' if dt.to_date == today
        return 'yesterday' if dt.to_date == today - 1
        return dt.strftime("%B") + sprintf(" %d, %d", dt.mday, dt.year)
      end
      
      def recipe_url(recipe, options = {})
        if !options[:public]
          url = "/recipe/#{recipe.id}"
        else
          url = recipe.public_url
        end
        
        if options[:multiplier]
          url << "?multiplier=#{options[:multiplier]}"
        end
        
        return url
      end
      
      def user_link(user)
        "/user/#{user.id}"
      end
      
      def js_escape(s)
        s.gsub("'", "\\\\'")
      end
      
      def try_host(url)
        URI.parse(url).host
      rescue Exception
        url
      end
      
      def ie_6?
        request.env['HTTP_USER_AGENT'] =~ /MSIE 6/
      end
      
      def ie_7?
        request.env['HTTP_USER_AGENT'] =~ /MSIE 7/
      end

      def tag_url(tag, options = {})
        tag_name = tag.is_a?(Tag) ? tag.name : tag
        options[:tag] = tag_name if tag_name
        options.delete(:top) unless options[:top]
        
        if options.size > 0
          '/recipe?' + options.to_query
        else
          '/recipe'
        end
      end
      
      def send_mail(*params)
        MF::Mailer.send_mail(*params)
      end
      
      def must_be_authed(options = {})
        raise_exception = options[:raise_exception]
        
        if !current_user.authed?
          if raise_exception
            raise UserException.new("Login Required", "Please login to view that page.")
          else
            session[:next] = request.path
            flash[:notice] = ["Login Required", "Please login to view that page."]
            redirect '/login'
          end
        end
      end
      
      def must_be_guest
        if current_user.authed?
          raise UserException.new("Already Logged In",
            "You are already logged as #{h current_user.name.strip}.")
        end
      end
      
      def required_params(*params)
        params.each do |key|
          if !request[key]
            raise UserException.new("Parameter Missing")
          end
        end
      end
      
      def pagination_arrows(dataset, record_name, make_path = nil)
        return "" if !dataset.prev_page && !dataset.next_page
        
        arrows = ""
        
        make_path ||= Proc.new do |page|
          if request.fullpath =~ /page=\d+/
            request.fullpath.gsub(/page=\d+/, "page=#{page}")
          elsif request.query_string.empty?
            request.fullpath + "?page=#{page}"
          else
            request.fullpath + "&page=#{page}"
          end
        end
                
        if !dataset.first_page?
          arrows << %Q{<a href="#{make_path.call(dataset.prev_page)}"><img src="/images/arrow_left.png"/></a>}
        end
                
        if !dataset.last_page?
          arrows << %Q{<a href="#{make_path.call(dataset.next_page)}"><img src="/images/arrow_right.png"/></a>}
        end
        
        %Q{
          <div class="pagination">#{arrows}</div>
        }
      end
      
      def current_page
        request[:page] ? request[:page].to_i : 1
      end
      
      def ingredient_to_html(i, options = {})
        if i.is_a?(ShoppingListItem)
          return i.name
        end
        
        if options[:multiplier]
          i = i * options[:multiplier]
        end
        
        ret = []
        
        # See if we can split.
        if (split = i.split).is_a?(Array) && !options[:ceiling]
          options[:all_fractions] = false
          options.delete(:multiplier)
          
          if split[0].quantity == 0
            return ingredient_to_html(split[1], options)
          else
            return ingredient_to_html(split[0], options) + " and " +
              ingredient_to_html(split[1], options)
          end
        end

        if i.quantity
          if i.unit && i.unit.type == Unit::MASS
            ret << ('%.2f' % i.quantity).sub(/0{1,2}$/, '').sub(/\.$/, '')
          else
            ret << number_to_html(i.quantity, options)
          end
        end
        
        if i.range
          ret.last << '-' << number_to_html(i.range, options)
        end
        
        ret << i.unit.abbr if i.unit
        ret << i.food if i.food

        return ret.join(' ')
      end
      
      def number_to_html(d, options = {})
        fraction = MF::Math.number_to_fraction(d,
          :ceiling => options[:ceiling],
          :all_fractions => options[:all_fractions])
        
        if fraction.is_a?(Integer)
          return fraction.to_s
        else
          html = nil
          
          if options[:html_fraction]
            MF::Math::ALL_FRACTIONS.each do |f|
              if f[0] == fraction[1] && f[1] == fraction[2]
                html = f[2]
              end
            end
          else
            html = "#{fraction[1]}/#{fraction[2]}"
          end
          
          return "#{fraction[0].to_s + (options[:html_fraction] ? '' : ' ') if fraction[0] != 0}#{html}"
        end
      end
      
      def use_javascript(name)
        (@javascripts ||= []) << name
      end
      
      def use_stylesheet(name, media = 'screen')
        (@stylesheets ||= []) << [name, media]
      end
      
      def print_javascripts
        return unless @javascripts
        ret = ""
        
        @javascripts.each do |script|
          url = if script.include?('http://')
            script
          else
            "/js/#{script}.js"
          end
          
          ret << %Q{<script type="text/javascript" src="#{url}"></script>\n}
        end
        
        return ret
      end
      
      def print_stylesheets
        return unless @stylesheets
        ret = ""
        
        @stylesheets.each do |style|
          url = if style[0].include?('http://')
            style[0]
          else
            "/css/#{style[0]}.css"
          end
          
          ret << %Q{<link rel="stylesheet" href="#{url}" type="text/css" media="#{style[1]}">\n}
        end
        
        return ret
      end
    end
  end
end