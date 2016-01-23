var Mealfire, buttonClicked, isIE, isIE6, isIE7, isIE8, makeRecipeBox;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
$(function() {
  var currentPopup;
  currentPopup = null;
  $('li.header_search input[type=text]').placeholder('Search Recipes');
  return $('a.schedule_recipe').click(function(e) {
    var id, title;
    if (currentPopup) {
      currentPopup.closeNow();
    }
    id = $(this).data('recipe-id');
    title = $(this).parent().find('.recipe-name').text();
    currentPopup = new Mealfire.Popup({
      title: "Schedule Recipe",
      width: 400,
      height: 365,
      scroll: true,
      data: '<p class="first">Select the day you\'d like to prepare "' + title + '".</p>' + '<div id="calendar"></div>',
      buttons: Mealfire.Buttons.closeOnly("Cancel")
    });
    $('#calendar').datepicker({
      onSelect: function(date) {
        currentPopup.loading();
        return $.post('/recipe/schedule', {
          id: id,
          date: date
        }, function() {
          return currentPopup.close();
        });
      }
    });
    return e.stopPropagation();
  });
});
if (typeof Mealfire === "undefined" || Mealfire === null) {
  Mealfire = {};
}
Mealfire.Buttons = {
  cancel: {
    text: "Cancel",
    click: function(popup) {
      popup.close();
      return false;
    }
  },
  close: {
    text: "Close",
    click: function(popup) {
      popup.close();
      return false;
    }
  },
  closeOnly: function(text) {
    return [
      {
        text: text || "Okay",
        isDefault: true,
        click: function(popup) {
          popup.close();
          return false;
        }
      }
    ];
  },
  standard: function(onClick, text) {
    return [
      Mealfire.Buttons.close, {
        text: text || "Submit",
        click: function(popup) {
          if (onClick) {
            if (onClick(popup) !== false) {
              popup.loading();
            }
            return false;
          }
        }
      }
    ];
  }
};
Mealfire.Popup = (function() {
  Popup.prototype.form = null;
  Popup.prototype.load_img = $('<div style="text-align:center;"><img class="progress" src="/images/progress.gif"></div>');
  function Popup(options) {
    var content, footer, form, left, popup, setupContent, top;
    options.width || (options.width = 400);
    options.height || (options.height = 300);
    popup = this;
    left = ($(window).width() - options.width) / 2 + $(document).scrollLeft();
    top = ($(window).height() - options.height) / 2 + $(document).scrollTop();
    form = $('<form class="popup"></form>');
    this.form = form;
    form.css({
      width: options.width + 'px',
      height: options.height + 'px',
      top: top + 'px',
      left: left + 'px'
    });
    if (options.form_params) {
      form.attr(options.form_params);
    }
    form.append($('<div class="north"></div>').css('width', (options.width - 20) + 'px'));
    form.append($('<div class="south"></div>').css('width', (options.width - 20) + 'px'));
    form.append($('<div class="east"></div>').css('height', (options.height - 20) + 'px'));
    form.append($('<div class="west"></div>').css('height', (options.height - 20) + 'px'));
    form.append('<div class="northwest"></div>');
    form.append('<div class="northeast"></div>');
    form.append('<div class="southwest"></div>');
    form.append('<div class="southeast"></div>');
    form.append($('<div class="header"></div>').css('width', (options.width - 32) + 'px').text(options.title));
    content = $('<td valign="middle"></td>').append(this.load_img);
    form.append($('<div class="content"></div>').css({
      width: (options.width - 42) + 'px',
      height: (options.height - (options.buttons ? 96 : 67)) + 'px',
      overflowY: options.scroll ? 'auto' : 'hidden',
      overflowX: 'hidden'
    }).append($('<table style="width:100%;height:100%"></table>').append($('<tr></tr>').append(content))));
    if (options.buttons) {
      footer = $('<div class="footer"></div>').css('width', (options.width - 32) + 'px');
      $.each(options.buttons.reverse(), function() {
        var b;
        b = $('<input class="submit_button" type="submit"/>');
        b.attr('value', this.text);
        b.click(__bind(function() {
          return this.click(popup, b);
        }, this));
        if (this.isDefault) {
          $(window).keyup(function(e) {
            var code;
            code = e.keyCode ? e.keyCode : e.which;
            if (code === 13) {
              return b.click();
            }
          });
        }
        return footer.append(b);
      });
      form.append(footer);
    }
    $(document.body).append(form);
    if (!$.browser.msie) {
      form.fadeIn('fast');
    }
    setupContent = __bind(function() {
      var entryElements;
      entryElements = $('input[type=text]:first, textarea:first', content);
      if (entryElements.length > 0) {
        entryElements[0].focus();
      }
      if (options.complete) {
        return options.complete(this);
      }
    }, this);
    if (options.url) {
      content.load(options.url, null, setupContent);
    }
    if (options.data) {
      content.html(options.data);
      setupContent();
    }
    if (options.dataFetcher) {
      options.dataFetcher(content);
    }
  }
  Popup.prototype.loading = function() {
    return $('td', this.form).html(this.load_img);
  };
  Popup.prototype.close = function() {
    if ($.browser.msie) {
      return this.closeNow();
    } else {
      return this.form.fadeOut('fast', __bind(function() {
        return this.closeNow();
      }, this));
    }
  };
  Popup.prototype.closeNow = function() {
    return this.form.remove();
  };
  return Popup;
})();
Mealfire.DynamicPopup = (function() {
  DynamicPopup.prototype.innerPopup = null;
  function DynamicPopup(options) {
    options.width || (options.width = 500);
    if (options.data) {
      this.showPopup(options, options.data);
    } else {
      this.fromUrl(options);
    }
  }
  DynamicPopup.prototype.fromUrl = function(options) {
    var waitingPopup;
    waitingPopup = new Mealfire.Popup({
      width: options.width,
      height: 150,
      title: 'Loading...'
    });
    return $.post(options.url, options.form_data, __bind(function(data) {
      waitingPopup.closeNow();
      return this.showPopup(options, data);
    }, this));
  };
  DynamicPopup.prototype.showPopup = function(options, data) {
    var div, height, scroll;
    div = $('<div style="float:left;display:none;"></div>').css("width", (options.width - 42) + 'px');
    $(document.body).append(div);
    div.html(data);
    height = div.height();
    div.remove();
    scroll = false;
    if (height > 350) {
      height = 350;
      scroll = true;
    }
    options.scroll = scroll;
    options.width = (options.width || 500) + (scroll ? 40 : 0);
    options.height = height + 110;
    options.data = data;
    return this.innerPopup = new Mealfire.Popup(options);
  };
  DynamicPopup.prototype.close = function() {
    return this.innerPopup.close();
  };
  return DynamicPopup;
})();
Mealfire.FormFieldPopup = (function() {
  FormFieldPopup.prototype.div = null;
  function FormFieldPopup(options) {
    options.field.focus(__bind(function() {
      return this.show(options);
    }, this));
    options.field.blur(__bind(function() {
      return this.hide();
    }, this));
  }
  FormFieldPopup.prototype.show = function(options) {
    var offset;
    offset = options.field.offset();
    this.div = $('<div></div>').css({
      display: 'none',
      position: 'absolute',
      left: (offset.left + options.field.width() + 20) + 'px',
      top: offset.top + 3 + 'px',
      width: '300px',
      textAlign: 'left',
      backgroundImage: 'url(/images/arrow_left_small.png)',
      paddingLeft: '15px',
      backgroundRepeat: 'no-repeat',
      backgroundPosition: '0 3px'
    });
    this.div.append(options.content);
    $(document.body).append(this.div);
    return this.div.fadeIn('fast');
  };
  FormFieldPopup.prototype.hide = function() {
    if (this.div) {
      return this.div.remove();
    }
  };
  return FormFieldPopup;
})();
Mealfire.CategoryList = (function() {
  function CategoryList(element, change) {
    var notify;
    element = $(element);
    notify = function() {
      var ids;
      ids = [];
      element.find('div.category_id').each(function() {
        return ids.push($(this).text());
      });
      return change(ids.join(','));
    };
    notify();
    element.sortable({
      axis: 'y',
      opacity: 0.5,
      update: notify,
      start: function() {
        return $(document.body).disableSelection();
      },
      stop: function() {
        return $(document.body).enableSelection();
      }
    });
  }
  return CategoryList;
})();
isIE = function() {
  return navigator.userAgent.indexOf('MSIE') > -1;
};
isIE6 = function() {
  return navigator.userAgent.indexOf('MSIE 6') > -1;
};
isIE7 = function() {
  return navigator.userAgent.indexOf('MSIE 7') > -1;
};
isIE8 = function() {
  return navigator.userAgent.indexOf('MSIE 8') > -1;
};
buttonClicked = function() {
  if (isIE()) {
    return alert('Right-click on this link, then select "Add to Favorites".');
  } else {
    return alert('Drag this link to your bookmarks toolbar.');
  }
};
Mealfire.startBusy = function(el) {
  var pos, waiting;
  el = $(el);
  pos = el.position();
  el.css('opacity', 0.5);
  waiting = $('<img src="/images/loading.png" />').css('z-index', '1000').css('position', 'absolute').css('top', pos.top + (el.height() / 2) - 15 + 'px').css('left', pos.left + (el.width() / 2) - 45 + 'px');
  el.data('waiting', waiting);
  return $(document.body).append(waiting);
};
Mealfire.endBusy = function(el) {
  $(el).data('waiting').remove();
  return $(el).css('opacity', 1);
};
makeRecipeBox = function(recipe) {
  var box;
  box = $('<div id="recipe_' + recipe.i + '" class="recipe_box in_panel">').append('<img src="/images/rb_left.png" class="left"/>').append($('<div class="middle">').text(recipe.n)).append('<img src="/images/rb_right.png" class="right"/>');
  if (recipe.t) {
    box.data('tags', recipe.t);
  }
  return box;
};
Mealfire.multiplierButton = function(options) {
  var remove;
  options.button = $(options.button);
  remove = function() {
    if (!($('div.dropdown_menu').length > 0)) {
      return;
    }
    options.button.data("attached", false);
    return $('div.dropdown_menu').each(function() {
      return $(this).remove();
    });
  };
  return options.button.click(function(e) {
    var box, div, input, item, submit;
    if (options.button.data("attached")) {
      remove();
      return;
    }
    input = $('<input type="text" value="' + options.current + '" style="width:60px;margin-right:5px;color:#888;">');
    input.click(function(e) {
      input.val('');
      input.css('color', '#333');
      return e.stopPropagation();
    });
    input.keyup(function(e) {
      if (e.keyCode === 13) {
        submit.click();
        return e.stopPropagation();
      }
    });
    submit = $('<input type="submit" class="submit_button" value="go">');
    submit.click(function() {
      var mult;
      mult = input.val();
      if (isNaN(parseFloat(mult)) || parseFloat(mult) <= 0) {
        input.val('');
        return new Mealfire.Popup({
          title: 'Multiplier Error',
          data: "Please enter a numerical value greater than zero.",
          width: 340,
          height: 125,
          buttons: Mealfire.Buttons.closeOnly()
        });
      } else {
        options.onChoose(mult);
        return remove();
      }
    });
    box = $(options.parent).find('.section_content');
    box.css('position', 'relative');
    div = $('<div class="dropdown_menu"></div>').css({
      display: 'none',
      position: 'absolute',
      top: options.top || '3px',
      right: '3px',
      width: '120px',
      zIndex: 10,
      whiteSpace: 'nowrap'
    });
    div.click(function(e) {
      return e.stopPropagation();
    });
    item = $('<div class="item"></div>').css({
      padding: '5px'
    });
    div.append(item.append(input).append(submit));
    box.append(div);
    div.toggle(150);
    $(document.body).click(function() {
      remove();
      return $(document.body).unbind('click', this);
    });
    options.button.data("attached", true);
    return e.stopPropagation();
  });
};
Mealfire.recipeURL = function(id, options) {
  var url;
  url = "/recipe/$id";
  if (options.multiplier) {
    url += "?multiplier=${options.multiplier}";
  }
  return url;
};
$.fn.placeholder = function(text) {
  var el;
  el = this;
  if ('placeholder' in document.createElement('input')) {
    el.attr('placeholder', text);
    return;
  }
  if (el.val() === '') {
    el.val(text);
    el.addClass('placeholder');
  }
  el.focus(function() {
    if (el.val() === text) {
      el.val('');
      return el.removeClass('placeholder');
    }
  });
  el.blur(function() {
    if (el.val() === '') {
      el.val(text);
      return el.addClass('placeholder');
    }
  });
  return el.closest('form').bind("submit", function() {
    return e.val('');
  });
};
String.prototype.titleCase = function() {
  return this.replace(/\w\S*/g, function(txt) {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
};