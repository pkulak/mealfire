if(typeof Mealfire == "undefined")
  var Mealfire = {};

Mealfire.Dropdown = function(options) {
  this.init(options);
};

$.extend(Mealfire.Dropdown.prototype, {
  options: null,
  
  init: function(options) {
    this.options = options;
    var dd = this;
    
    if (options.parent) {
      options.element.css({visibility: 'hidden'});
      
      options.parent.mouseover(function() {
        if ($('div.dropdown_menu').length == 0) {
          options.element.css({visibility: 'visible'});
        }
      }).mouseout(function() {
        if ($('div.dropdown_menu').length == 0) {
          options.element.css({visibility: 'hidden'});
        }
      });
    }
    
    options.element.click(function(e) {
      dd.show(options, e);
      return false;
    })
  },
  
  show: function(options, e) {
    var dd = this;
    var offset = options.element.offset();
    var div = $('<div class="dropdown_menu"></div>');
    options.heightAddition = options.heightAddition || 0;
    options.cancelText = options.cancelText || 'Cancel';
    
    div.css({
      display: 'none',
      position: 'absolute',
      top: (offset.top + options.element.height() + 2 + options.heightAddition) + 'px',
      left: offset.left + 'px',
      width: (options.width || 100) + 'px'
    });
    
    options.items.push({
      text: options.cancelText,
      click: function() {
        dd.remove();
      }
    });

    $.each(options.items, function() {
      var item = this;
      var item_div = $('<div class="item"></div>');
      item_div.append(this.text);
      
      if (item.click) {
        item_div.click(function() {
          item.click();
          dd.remove();
        });
      
        item_div.mouseover(function() {
          item_div.addClass("hover")
        });
      
        item_div.mouseout(function() {
          item_div.removeClass("hover");
        })
      } else {
        item_div.addClass('notClickable');
        item_div.click(function(e) {
          e.stopPropagation();
        });
      }
      
      if (this != options.items[0]) {
        item_div.addClass("notFirst");
      }
      
      div.append(item_div);
    });
    
    options.items.pop();
    
    $(document.body).click(function() {
      dd.remove();
      $(document.body).unbind('click', this);
    });
    
    $(document.body).append(div);
    div.toggle(150);
    e.stopPropagation();
  },
  
  remove: function() {
    if ($('div.dropdown_menu').length == 0) {
      return;
    }

    if (this.options.parent) {
      this.options.element.css('visibility', 'hidden');
    }
    
    $.each($('div.dropdown_menu'), function() {
      $(this).remove();
    })
  }
});