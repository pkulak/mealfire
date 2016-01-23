$.jQTouch({
  icon: '/images/mobile/icon.png',
  startupScreen: '/images/mobile/startup.png',
  preloadImages: ['/images/check_mark.jpg']
});

$(function() {
  $('#recipes').bind('pageTransitionEnd', function(e, info) {
    if (info.direction == 'in' && $(this).data('loaded') != 'true') {
      $(this).append($('<div id="loading">Loading&hellip;</div>'));
      
      $.ajax({type: 'GET', dataType: 'json',
        url: '/mobile/all_recipes',
        success: loadRecipes
      });
    }
  });
  
  $('#add_item').bind('pageTransitionEnd', function(e, info) {
    $('#item').focus();
  })
  
  $('#login_button').click(function () {
    var data = {
      email: $('#email').val(),
      password: $('#password').val()
    }
    
    $.post('/mobile/login', data, function(resp) {
      if (resp == 'success') {
        window.location = '/mobile';
      } else {
        alert(resp);
      }
    });
  });
  
  $('#add_extras_button, #extras_home_button').click(function() {
    if ($('#edit_extras_button').data('edit_mode') == 'true') {
      $('#edit_extras_button').click();
    }
  });
  
  $('#add_item_button').click(function () {
    $.post('/mobile/add_item', {text: $('#item').val()}, function(resp) {
      if (resp.indexOf('error') == -1) {
        var img = $('<img src="/images/mobile/delete.png"/>').attr('id', 'delete_' + resp);
        var li = $('<li></li>').text($('#item').val()).append(img);
        setupDeleteButton(img);
          
        $('#shopping_list_holder').append(li);
        $('#item').val('');
        $('#add_item div.toolbar a').click();
      } else {
        alert(resp.split(':')[1]);
      }
    });
  });
  
  $('#edit_extras_button').click(function() {
    if ($(this).data('edit_mode') == 'true') {
      $('#shopping_list_holder img').css('right', '-35px');      
      $(this).data('edit_mode', 'false');
      $(this).text('Edit');
    } else {
      $('#shopping_list_holder img').css('right', '0');
      $(this).data('edit_mode', 'true');
      $(this).text('Done');
    }
  });
  
  $.each($('#shopping_list_holder img'), function() {
    setupDeleteButton($(this));
  });
});

function loadRecipes(recipes) {
  $('#loading').remove();
  
  $.each(recipes, function() {
    var li = $('<li></li>');
    var a = $('<a href="#recipe"></a>');
    a.attr('id', this.id);
    li.append(a);
    a.html(this.n);
    $('#recipes_holder').append(li);
  });
  
  $('#recipes_holder a').click(function() {
    $('#recipe_holder').html('');
    $('#recipe_holder').load('/mobile/get_recipe/' + this.id);
  });
  
  $('#recipes').data('loaded', 'true');
}

function setupDeleteButton(button) {
  button.click(function() {
    var id = button.attr('id').split('_')[1];
    button.css('-webkit-transform', 'rotate(90deg)');
    
    $.post('/mobile/delete_item/' + id, function() {
      button.closest('li').remove();
    });
  });
}

function loadSavedList(id) {
  $('#saved_list_holder').html('');
  
  $.ajax({type: 'GET', dataType: 'json',
    url: '/mobile/get_saved_list/' + id,
    success: function(categories) {
      $.each(categories, function() {
        $('#saved_list_holder').append($('<li class="category"></li>').text(this.name));

        $.each(this.children, function() {
          var li = $('<li class="ingredient">' + this + '</li>');
          
          li.click(function() {
            var me = $(this);
            
            if (me.hasClass("deleted"))
              me.removeClass("deleted");
            else
              me.addClass("deleted");
          })
          
          $('#saved_list_holder').append(li);
        });
      })
    }
  });
}