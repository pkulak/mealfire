var endBusy, jQT, loadSavedList, setupDeleteButton, startBusy;
startBusy = function(el) {
  var pos, waiting;
  el = $(el);
  pos = el.position();
  waiting = $('<img id="loading_img" src="/images/mobile/activityindicator.png" />').css('z-index', '1000').css('position', 'absolute').css('top', pos.top + (el.height() / 2) - 15 + 'px').css('left', pos.left + (el.width() / 2) - 15 + 'px');
  el.data('waiting', waiting);
  return el.append(waiting);
};
endBusy = function(el) {
  return $(el).data('waiting').remove();
};
jQT = new $.jQTouch({
  icon: '/images/mobile/icon_57.png',
  startupScreen: '/images/mobile/startup.png'
});
$(function() {
  $.post("/mobile/login_check", function(res) {
    if (res === '0') {
      return jQT.goTo('#login', 'slideup');
    }
  });
  $('#recipes').bind('pageAnimationEnd', function(e, info) {
    if (info.direction === 'in' && $(this).data('loaded') !== 'true') {
      startBusy(this);
      return $.getJSON('/mobile/all_recipes', function(res) {
        endBusy('#recipes');
        $.each(res, function() {
          var a, li;
          li = $('<li></li>');
          a = $('<a href="#recipe"></a>');
          a.attr('id', this[0]);
          li.append(a);
          a.html(this[1]);
          a.data('recipe_id', this[0]);
          return $('#recipes_holder').append(li);
        });
        return $('#recipes').data('loaded', 'true');
      });
    }
  });
  $('#recipe').bind('pageAnimationStart', function(e, info) {
    var id;
    if (info.direction !== 'in') {
      return;
    }
    id = $(this).data('referrer').data('recipe_id');
    $('#recipe_title').text($(this).data('referrer').text());
    $('#recipe_holder').html('');
    startBusy('#recipe');
    return $('#recipe_holder').load('/mobile/get_recipe/' + id, function() {
      return endBusy('#recipe');
    });
  });
  $('#add_item').bind('pageAnimationEnd', function(e, info) {
    return $('#item').focus();
  });
  $('#extra').bind('pageAnimationEnd', function(e, info) {
    if (info.direction !== 'in' || $(this).data('loaded') === 'true') {
      return;
    }
    $('#shopping_list_holder').html('');
    startBusy(this);
    return $.getJSON('/mobile/get_shopping_list_items', function(res) {
      $.each(res, function() {
        var img, li;
        img = $('<img src="/images/mobile/delete.png"/>').attr('id', 'delete_' + this[0]).css('display', 'none');
        li = $('<li></li>').text(this[1]).append(img);
        setupDeleteButton(img);
        return $('#shopping_list_holder').append(li);
      });
      $('#extra').data('loaded', 'true');
      return endBusy('#extra');
    });
  });
  $('#add_extras_button, #extras_home_button').click(function() {
    if ($('#edit_extras_button').data('edit_mode') === 'true') {
      return $('#edit_extras_button').click();
    }
  });
  $('#edit_extras_button').click(function() {
    if ($(this).data('edit_mode') === 'true') {
      $('#shopping_list_holder img').css('display', 'none');
      $(this).data('edit_mode', 'false');
      return $(this).text('Edit');
    } else {
      $('#shopping_list_holder img').css('display', 'inline');
      $(this).data('edit_mode', 'true');
      return $(this).text('Done');
    }
  });
  $('#add_item_button').click(function() {
    return $.post('/mobile/add_item', {
      text: $('#item').val()
    }, function(resp) {
      var img, li;
      if (resp.indexOf('error') === -1) {
        img = $('<img src="/images/mobile/delete.png"/>').attr('id', 'delete_' + resp);
        li = $('<li></li>').text($('#item').val()).append(img);
        setupDeleteButton(img);
        $('#shopping_list_holder').append(li);
        $('#item').val('');
        return jQT.goTo('#extra');
      } else {
        return alert(resp.split(':')[1]);
      }
    });
  });
  $('#saved_lists').bind('pageAnimationEnd', function(e, info) {
    if (info.direction !== 'in' || $(this).data('loaded') === 'true') {
      return;
    }
    startBusy(this);
    return $.getJSON('/mobile/get_saved_lists', function(res) {
      $.each(res, function() {
        var anchor, li;
        anchor = $('<a href="#saved_list"></a>').text(this[1]);
        li = $('<li></li>').append(anchor);
        anchor.data('saved_list_id', this[0]);
        return $('#saved_lists_holder').append(li);
      });
      $('#saved_lists').data('loaded', 'true');
      return endBusy('#saved_lists');
    });
  });
  $('#saved_list').bind('pageAnimationStart', function(e, info) {
    if (!(info.direction === 'in' && loadSavedList($(this).data('referrer').data('saved_list_id')))) {
      ;
    }
  });
  return $('#login_button').click(function() {
    var data;
    data = {
      email: $('#email').val(),
      password: $('#password').val()
    };
    return $.post('/mobile/login', data, function(resp) {
      if (resp === 'success') {
        return jQT.goBack();
      } else {
        return alert(resp);
      }
    });
  });
});
setupDeleteButton = function(button) {
  return button.click(function() {
    var id;
    id = button.attr('id').split('_')[1];
    button.css('-webkit-transform', 'rotate(90deg)');
    return $.post('/mobile/delete_item/' + id, function() {
      return button.closest('li').remove();
    });
  });
};
loadSavedList = function(id) {
  $('#saved_list_holder').html('');
  startBusy('#saved_list');
  return $.ajax({
    type: 'GET',
    dataType: 'json',
    url: '/mobile/get_saved_list/' + id,
    success: function(categories) {
      $.each(categories, function() {
        $('#saved_list_holder').append($('<li class="category"></li>').text(this.name));
        return $.each(this.children, function() {
          var li;
          li = $('<li class="ingredient">' + this + '</li>');
          li.click(function() {
            var me;
            me = $(this);
            if (me.hasClass("deleted")) {
              return me.removeClass("deleted");
            } else {
              return me.addClass("deleted");
            }
          });
          return $('#saved_list_holder').append(li);
        });
      });
      return endBusy('#saved_list');
    }
  });
};