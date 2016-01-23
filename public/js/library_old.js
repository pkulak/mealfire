if(typeof Mealfire == "undefined")
  var Mealfire = {};

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
    return [{
      text: text || "Okay",
      isDefault: true,
      click: function(popup) {
        popup.close();
        return false;
      }
    }];
  },
  
  standard: function(click, text) {
    return [
      Mealfire.Buttons.close,
      {text: text || "Submit", click: function(popup) {
        if (click) {
          click(popup);
          popup.loading();
          return false;
        }
      }}
    ]
  }
};

Mealfire.Popup = function(options) {
  this.init(options);
};

$.extend(Mealfire.Popup.prototype, {
  form: null,
  load_img: $('<div style="text-align:center;"><img class="progress" src="/images/progress.gif"></div>'),
  
  init: function(options) {
    var popup = this;
    options.width = options.width || 400;
    options.height = options.height || 300;
    
    var left = ($(window).width() - options.width) / 2 + $(document).scrollLeft();
    var top = ($(window).height() - options.height) / 2 + $(document).scrollTop();
    
    var form = $('<form class="popup"></form>');
    
    if (!$.browser.msie)
      form.css('display', 'none');
    
    this.form = form;
    
    form.css({
      width: options.width + 'px',
      height: options.height + 'px',
      top: top + 'px',
      left: left + 'px'});
    
    if (options.form_params)
      form.attr(options.form_params);
    
    form.append($('<div class="north"></div>').css('width', (options.width - 20) + 'px'));
    form.append($('<div class="south"></div>').css('width', (options.width - 20) + 'px'));
    form.append($('<div class="east"></div>').css('height', (options.height - 20) + 'px'));
    form.append($('<div class="west"></div>').css('height', (options.height - 20) + 'px'));
    form.append('<div class="northwest"></div>');
    form.append('<div class="northeast"></div>');
    form.append('<div class="southwest"></div>');
    form.append('<div class="southeast"></div>');
    
    form.append($('<div class="header"></div>').css('width', (options.width - 32) + 'px')
      .text(options.title));
    
    var content = $('<td valign="middle"></td>').append(this.load_img);
    
    form.append(
      $('<div class="content"></div>').css({
          width: (options.width - 42) + 'px',
          height: (options.height - (options.buttons ? 96 : 67)) + 'px',
          overflowY: options.scroll ? 'auto' : 'hidden',
          overflowX: 'hidden'})
        .append($('<table style="width:100%;height:100%"></table>')
          .append($('<tr></tr>')
            .append(content)))
    );
    
    if (options.buttons) {
      var footer = $('<div class="footer"></div>').css('width', (options.width - 32) + 'px');
    
      $.each(options.buttons.reverse(), function() {
        var click = this.click;
        var b = $('<input class="submit_button" type="submit"/>');
        b.attr('value', this.text);
      
        b.click(function() {
          return click(popup, b);
        });
        
        if (this.isDefault) {
          $(window).keyup(function(e) {
            var code = (e.keyCode ? e.keyCode : e.which);
            if (code == 13) {
              b.click();
            }
          });
        }
        
        footer.append(b);
      });
    
      form.append(footer);
    }
    
    $(document.body).append(form);
    
    if (!$.browser.msie)
      form.fadeIn('fast');
    
    var setupContent = function() {
      var entryElements = $('input[type=text]:first, textarea:first', content);
      
      if (entryElements.length > 0)
        entryElements[0].focus();
      
      if (options.complete)
        options.complete(popup);
    }
    
    if (options.url)
      content.load(options.url, null, setupContent);
    
    if (options.data) {
      content.html(options.data);
      setupContent();
    }
    
    if (options.dataFetcher) {
      options.dataFetcher(content);
    }
  },
  
  loading: function() {
    $('td', this.form).html(this.load_img);
  },
  
  close: function() {
    if ($.browser.msie) {
      this.closeNow();
    } else {
      var popup = this;
    
      this.form.fadeOut('fast', function() {
        popup.closeNow();
      });
    }
  },
  
  closeNow: function() {
    this.form.remove();
    $(window).unbind("keyup", this.onEnter);
  }
});

Mealfire.DynamicPopup = function(options) {
  this.init(options);
};

$.extend(Mealfire.DynamicPopup.prototype, {
  innerPopup: null,
  
  init: function(options) {
    options.width = options.width || 500;
    
    if (options.data) {
      this.showPopup(options, options.data);
    } else {
      this.fromUrl(options);
    }
  },
  
  fromUrl: function(options) {
    var that = this;
    
    var waitingPopup = new Mealfire.Popup({
      width: options.width,
      height: 150,
      title: 'Loading...'
    });
    
    $.post(options.url, options.form_data, function(data) {
      waitingPopup.closeNow();
      that.showPopup(options, data);
    });
  },
  
  showPopup: function(options, data) {
    var div = $('<div style="float:left;display:none;"></div>')
      .css("width", (options.width - 42) + 'px');
    
    $(document.body).append(div);
    div.html(data);
    var height = div.height();
    div.remove();

    var scroll = false;
    
    if (height > 350) {
      height = 350;
      scroll = true;
    }

    options.scroll = scroll;
    options.width = (options.width || 500) + (scroll ? 40 : 0);
    options.height = height + 110;
    options.data = data;
    
    this.innerPopup = new Mealfire.Popup(options);
  },
  
  close: function() {
    this.innerPopup.close();
  }
});

Mealfire.FormFieldPopup = function(options) {
  this.init(options);
};

$.extend(Mealfire.FormFieldPopup.prototype, {
  div: null,
  
  init: function(options) {
    var that = this;
    
    options.field.focus(function() {
      that.show(options);
    }).blur(function() {
      that.hide();
    });
  },
  
  show: function(options) {
    var offset = options.field.offset();
    
    var div = $('<div></div>').css({
      display: 'none',
      position: 'absolute',
      left: (offset.left + options.field.width() + 20) + 'px',
      top: offset.top + 'px',
      width: '300px',
      textAlign: 'left',
      backgroundImage: 'url(/images/arrow_left_small.png)',
      paddingLeft: '15px',
      backgroundRepeat: 'no-repeat',
      backgroundPosition: '0 3px'
    });
    
    div.append(options.content);
    $(document.body).append(div);
    div.fadeIn('fast');
    this.div = div;
  },
  
  hide: function() {
    if (this.div)
      this.div.remove();
  }
});

Mealfire.NotePopup = function(options) {
  this.init(options);
};

$.extend(Mealfire.NotePopup.prototype, {
  container: null,
  
  init: function(options) {
    var container = $('<div></div>').css({
      position: 'absolute',
      top: options.top + 'px',
      left: (options.left + 11) + 'px'
    });
    
    var image = $('<img src="/images/popup_arrow_left.png"/>').css({
      'float': 'left'
    })
    
    var data = $('<div></div>').css({
      'float': 'left',
      height: '16px',
      backgroundColor: '#91FA00',
      borderTop: '1px solid #000',
      borderBottom: '1px solid #000',
      borderRight: '1px solid #000',
      padding: '2px 5px',
      fontWeight: 'bold',
      fontSize: '12px'
    });
    
    var close = $('<img src="/images/close.png"/>').css({
      'float': 'right',
      marginLeft: '5px',
      cursor: 'pointer'
    });
    
    close.click(function() {
      container.remove();
    });
    
    container.append(image).append(data.append(options.data).append(close));
    
    $(document.body).append(container);
    
    var animate = function() {
      container.animate({left: (options.left + 50) + 'px'}, 200, null, function() {
        container.animate({left: (options.left + 11) + 'px'}, 2000);
      });
      
      setTimeout(animate, 15000);
    }
    
    animate();
    this.container = container;
  },
  
  close: function() {
    this.container.remove();
  }
});

function isIE() {
  return navigator.userAgent.indexOf('MSIE') > -1
}

function isIE6() {
  return navigator.userAgent.indexOf('MSIE 6') > -1
}

function isIE7() {
  return navigator.userAgent.indexOf('MSIE 7') > -1
}

function isIE8() {
  return navigator.userAgent.indexOf('MSIE 8') > -1
}

function buttonClicked() {
  if (isIE()) {
    alert('Right-click on this link, then select "Add to Favorites".');
  } else {
    alert('Drag this link to your bookmarks toolbar.');
  }
}

Mealfire.startBusy = function(el) {
  el = $(el);
  el.css('opacity', 0.5);
  var pos = el.position();
  
  var waiting = $('<img src="/images/loading.png" />')
    .css('z-index', '1000')
    .css('position', 'absolute')
    .css('top', pos.top + (el.height() / 2) - 15 + 'px')
    .css('left', pos.left + (el.width() / 2) - 45 + 'px');
  
  el.data('waiting', waiting);
  $(document.body).append(waiting);
}

Mealfire.endBusy = function(el) {
  $(el).data('waiting').remove();
  $(el).css('opacity', 1);
}

function makeRecipeBox(recipe) {
  var box = $('<div id="recipe_' + recipe.i + '" class="recipe_box in_panel">')
    .append('<img src="/images/rb_left.png" class="left"/>')
    .append($('<div class="middle">').text(recipe.n))
    .append('<img src="/images/rb_right.png" class="right"/>')
  
  if (recipe.t) {
    box.data('tags', recipe.t);
  }
  
  return box;
}