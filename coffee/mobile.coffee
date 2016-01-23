startBusy = (el) ->
  el = $(el)
  pos = el.position()
  
  waiting = $('<img id="loading_img" src="/images/mobile/activityindicator.png" />')
    .css('z-index', '1000')
    .css('position', 'absolute')
    .css('top', pos.top + (el.height() / 2) - 15 + 'px')
    .css('left', pos.left + (el.width() / 2) - 15 + 'px')

  el.data('waiting', waiting)
  el.append(waiting)

endBusy = (el) ->
  $(el).data('waiting').remove()

jQT = new $.jQTouch
  icon: '/images/mobile/icon_57.png'
  startupScreen: '/images/mobile/startup.png'

$ ->
  # Make sure we're logged in
  $.post "/mobile/login_check", (res) ->
    if res == '0'
      jQT.goTo('#login', 'slideup');

  $('#recipes').bind 'pageAnimationEnd', (e, info) ->
    if info.direction == 'in' && $(this).data('loaded') != 'true'
      startBusy(this)
      
      $.getJSON '/mobile/all_recipes', (res) ->
        endBusy('#recipes')

        $.each res, ->
          li = $('<li></li>')
          a = $('<a href="#recipe"></a>')
          a.attr('id', this[0])
          li.append(a)
          a.html(this[1])
          a.data('recipe_id', this[0])
          $('#recipes_holder').append(li)

        $('#recipes').data('loaded', 'true')
  
  $('#recipe').bind 'pageAnimationStart', (e, info) ->
    return unless info.direction == 'in'
    
    id = $(this).data('referrer').data('recipe_id')
    $('#recipe_title').text($(this).data('referrer').text())
    $('#recipe_holder').html('')
    startBusy('#recipe')
    $('#recipe_holder').load('/mobile/get_recipe/' + id, -> endBusy('#recipe'))
  
  $('#add_item').bind 'pageAnimationEnd', (e, info) ->
    $('#item').focus()
  
  $('#extra').bind 'pageAnimationEnd', (e, info) ->
    if info.direction != 'in' || $(this).data('loaded') == 'true'
      return
    
    $('#shopping_list_holder').html('')
    startBusy(this)
    
    $.getJSON '/mobile/get_shopping_list_items', (res) ->
      $.each res, ->
        img = $('<img src="/images/mobile/delete.png"/>')
          .attr('id', 'delete_' + this[0])
          .css('display', 'none')
          
        li = $('<li></li>').text(this[1]).append(img)
        setupDeleteButton(img)
        $('#shopping_list_holder').append(li)
      
      $('#extra').data('loaded', 'true')
      endBusy('#extra')
  
  $('#add_extras_button, #extras_home_button').click ->
    if $('#edit_extras_button').data('edit_mode') == 'true'
      $('#edit_extras_button').click()
      
  $('#edit_extras_button').click ->
    if $(this).data('edit_mode') == 'true'
      $('#shopping_list_holder img').css('display', 'none')
      $(this).data('edit_mode', 'false')
      $(this).text('Edit')
    else
      $('#shopping_list_holder img').css('display', 'inline')        
      $(this).data('edit_mode', 'true')
      $(this).text('Done')
  
  $('#add_item_button').click ->
    $.post '/mobile/add_item', {text: $('#item').val()}, (resp) ->
      if resp.indexOf('error') == -1
        img = $('<img src="/images/mobile/delete.png"/>').attr('id', 'delete_' + resp)
        li = $('<li></li>').text($('#item').val()).append(img)
        setupDeleteButton(img)

        $('#shopping_list_holder').append(li)
        $('#item').val('')
        jQT.goTo('#extra')
      else
        alert(resp.split(':')[1])
  
  $('#saved_lists').bind 'pageAnimationEnd', (e, info) ->
    if info.direction != 'in' || $(this).data('loaded') == 'true'
      return
    
    startBusy(this)
    
    $.getJSON '/mobile/get_saved_lists', (res) ->
      $.each res, ->
        anchor = $('<a href="#saved_list"></a>').text(this[1])
        li = $('<li></li>').append(anchor)
        
        anchor.data('saved_list_id', this[0])
        $('#saved_lists_holder').append(li)
      
      $('#saved_lists').data('loaded', 'true')
      endBusy('#saved_lists')
  
  $('#saved_list').bind 'pageAnimationStart', (e, info) ->
    return unless info.direction == 'in' && 
    
    loadSavedList($(this).data('referrer').data('saved_list_id'));
  
  $('#login_button').click ->
    data =
      email: $('#email').val()
      password: $('#password').val()
    
    $.post '/mobile/login', data, (resp) ->
      if resp == 'success'
        jQT.goBack()
      else
        alert(resp)

setupDeleteButton = (button) ->
  button.click ->
    id = button.attr('id').split('_')[1]
    button.css('-webkit-transform', 'rotate(90deg)')

    $.post '/mobile/delete_item/' + id, ->
      button.closest('li').remove()

loadSavedList = (id) ->
  $('#saved_list_holder').html('')
  startBusy('#saved_list')

  $.ajax
    type: 'GET'
    dataType: 'json'
    url: '/mobile/get_saved_list/' + id
    success: (categories) ->
      $.each categories, ->
        $('#saved_list_holder').append($('<li class="category"></li>').text(this.name))

        $.each this.children, ->
          li = $('<li class="ingredient">' + this + '</li>')

          li.click ->
            me = $(this);

            if (me.hasClass("deleted"))
              me.removeClass("deleted")
            else
              me.addClass("deleted")

          $('#saved_list_holder').append(li)
      
      endBusy('#saved_list')