$ ->
  currentPopup = null

  $('li.header_search input[type=text]').placeholder('Search Recipes')
  
  $('a.schedule_recipe').click (e) ->
    currentPopup.closeNow() if currentPopup
    
    id = $(this).data('recipe-id')
    title = $(this).parent().find('.recipe-name').text()
    
    currentPopup = new Mealfire.Popup
      title: "Schedule Recipe"
      width: 400
      height: 365
      scroll: true
      data: '<p class="first">Select the day you\'d like to prepare "' + title + '".</p>' +
              '<div id="calendar"></div>'
      buttons: Mealfire.Buttons.closeOnly("Cancel")
    
    $('#calendar').datepicker
      onSelect: (date) ->
        currentPopup.loading()
        
        $.post '/recipe/schedule', {id: id, date: date}, ->
          currentPopup.close()
    
    e.stopPropagation()

Mealfire = {} unless Mealfire?

Mealfire.Buttons =
  cancel:
    text: "Cancel"
    click: (popup) ->
      popup.close()
      false
  
  close:
    text: "Close"
    click: (popup) ->
      popup.close()
      false
  
  closeOnly: (text) ->
    [{
      text: text || "Okay"
      isDefault: true
      click: (popup) ->
        popup.close()
        false
    }]
  
  standard: (onClick, text) ->
    [
      Mealfire.Buttons.close
      {text: text || "Submit", click: (popup) ->
        if onClick
          if onClick(popup) != false
            popup.loading()
          false
      }
    ]

class Mealfire.Popup
  form: null
  load_img: $('<div style="text-align:center;"><img class="progress" src="/images/progress.gif"></div>')
  
  constructor: (options) ->
    options.width ||= 400
    options.height ||= 300
    
    popup = this
    left = ($(window).width() - options.width) / 2 + $(document).scrollLeft()
    top = ($(window).height() - options.height) / 2 + $(document).scrollTop()
    
    form = $('<form class="popup"></form>')
    @form = form
    
    form.css
      width: options.width + 'px'
      height: options.height + 'px'
      top: top + 'px'
      left: left + 'px'
    
    if options.form_params
      form.attr(options.form_params)
    
    form.append($('<div class="north"></div>').css('width', (options.width - 20) + 'px'))
    form.append($('<div class="south"></div>').css('width', (options.width - 20) + 'px'))
    form.append($('<div class="east"></div>').css('height', (options.height - 20) + 'px'))
    form.append($('<div class="west"></div>').css('height', (options.height - 20) + 'px'))
    form.append('<div class="northwest"></div>')
    form.append('<div class="northeast"></div>')
    form.append('<div class="southwest"></div>')
    form.append('<div class="southeast"></div>')
    
    form.append($('<div class="header"></div>')
      .css('width', (options.width - 32) + 'px')
      .text(options.title))
    
    content = $('<td valign="middle"></td>').append(@load_img)
    
    form.append(
      $('<div class="content"></div>').css({
        width: (options.width - 42) + 'px'
        height: (options.height - (if options.buttons then 96 else 67)) + 'px'
        overflowY: if options.scroll then 'auto' else 'hidden'
        overflowX: 'hidden'
      })
      .append($('<table style="width:100%;height:100%"></table>')
        .append($('<tr></tr>')
          .append(content))))
    
    if options.buttons
      footer = $('<div class="footer"></div>').css('width', (options.width - 32) + 'px')
      
      $.each options.buttons.reverse(), ->
        b = $('<input class="submit_button" type="submit"/>')

        b.attr('value', this.text)
        b.click => this.click(popup, b)
        
        if this.isDefault
          $(window).keyup (e) ->
            code = if e.keyCode then e.keyCode else e.which
            b.click() if code == 13
        
        footer.append(b)
      
      form.append footer
    
    $(document.body).append(form);
    
    if !$.browser.msie
      form.fadeIn('fast');
    
    setupContent = =>
      entryElements = $('input[type=text]:first, textarea:first', content)
      
      entryElements[0].focus() if entryElements.length > 0
      options.complete(this) if options.complete
    
    if options.url
      content.load(options.url, null, setupContent)
    
    if options.data
      content.html(options.data)
      setupContent()
    
    if options.dataFetcher
      options.dataFetcher(content)
  
  loading: ->
    $('td', this.form).html(this.load_img)
  
  close: ->
    if $.browser.msie
      this.closeNow();
    else    
      @form.fadeOut('fast', =>
        @closeNow())
  
  closeNow: ->
    @form.remove()
    
class Mealfire.DynamicPopup
  innerPopup: null
  
  constructor: (options) ->
    options.width ||= 500
    
    if options.data
      @showPopup(options, options.data)
    else
      @fromUrl(options)
  
  fromUrl: (options) ->    
    waitingPopup = new Mealfire.Popup
      width: options.width
      height: 150
      title: 'Loading...'
    
    $.post options.url, options.form_data, (data) =>
      waitingPopup.closeNow()
      this.showPopup(options, data)
  
  showPopup: (options, data) ->
    div = $('<div style="float:left;display:none;"></div>')
      .css("width", (options.width - 42) + 'px')
    
    $(document.body).append(div)
    div.html(data)
    height = div.height()
    div.remove()
    
    scroll = false
    
    if height > 350
      height = 350
      scroll = true

    options.scroll = scroll
    options.width = (options.width || 500) + (if scroll then 40 else 0)
    options.height = height + 110
    options.data = data
    
    @innerPopup = new Mealfire.Popup(options)
  
  close: ->
    @innerPopup.close()

class Mealfire.FormFieldPopup
  div: null
  
  constructor: (options) ->
    options.field.focus =>
      this.show(options)
    
    options.field.blur =>
      this.hide()
  
  show: (options) ->
    offset = options.field.offset()
    
    @div = $('<div></div>').css
      display: 'none'
      position: 'absolute'
      left: (offset.left + options.field.width() + 20) + 'px'
      top: offset.top + 3 + 'px'
      width: '300px'
      textAlign: 'left'
      backgroundImage: 'url(/images/arrow_left_small.png)'
      paddingLeft: '15px'
      backgroundRepeat: 'no-repeat'
      backgroundPosition: '0 3px'
    
    @div.append(options.content)
    $(document.body).append(@div)
    @div.fadeIn('fast')

  hide: ->
    @div.remove() if @div

class Mealfire.CategoryList
  constructor: (element, change) ->
    element = $(element)
    
    notify = ->
      ids = []

      element.find('div.category_id').each ->
        ids.push($(this).text())

      change(ids.join(','))
    
    notify()
  
    element.sortable
      axis: 'y'
      opacity: 0.5
      update: notify
      start: -> $(document.body).disableSelection()
      stop: -> $(document.body).enableSelection()

isIE = -> navigator.userAgent.indexOf('MSIE') > -1
isIE6 = -> navigator.userAgent.indexOf('MSIE 6') > -1
isIE7 = -> navigator.userAgent.indexOf('MSIE 7') > -1
isIE8 = -> navigator.userAgent.indexOf('MSIE 8') > -1

buttonClicked = ->
  if isIE()
    alert('Right-click on this link, then select "Add to Favorites".');
  else
    alert('Drag this link to your bookmarks toolbar.');

Mealfire.startBusy = (el) ->
  el = $(el)
  pos = el.position()
  
  el.css('opacity', 0.5)

  waiting = $('<img src="/images/loading.png" />')
    .css('z-index', '1000')
    .css('position', 'absolute')
    .css('top', pos.top + (el.height() / 2) - 15 + 'px')
    .css('left', pos.left + (el.width() / 2) - 45 + 'px')

  el.data('waiting', waiting)
  $(document.body).append(waiting)

Mealfire.endBusy = (el) ->
  $(el).data('waiting').remove()
  $(el).css('opacity', 1)

makeRecipeBox = (recipe) ->
  box = $('<div id="recipe_' + recipe.i + '" class="recipe_box in_panel">')
    .append('<img src="/images/rb_left.png" class="left"/>')
    .append($('<div class="middle">').text(recipe.n))
    .append('<img src="/images/rb_right.png" class="right"/>')

  if recipe.t
    box.data('tags', recipe.t)

  box
  
Mealfire.multiplierButton = (options) ->
  options.button = $(options.button)
  
  remove = ->
    return unless $('div.dropdown_menu').length > 0
    options.button.data("attached", false)
    
    $('div.dropdown_menu').each ->
      $(this).remove()
  
  options.button.click (e) ->
    if options.button.data("attached")
      remove()
      return
  
    input = $('<input type="text" value="' + options.current + '" style="width:60px;margin-right:5px;color:#888;">')
    
    input.click (e) ->
      input.val('')
      input.css('color', '#333')
      e.stopPropagation()
      
    input.keyup (e) ->
      if e.keyCode == 13
        submit.click()
        e.stopPropagation()
    
    submit = $('<input type="submit" class="submit_button" value="go">')
      
    submit.click ->
      mult = input.val()
      
      if isNaN(parseFloat(mult)) || parseFloat(mult) <= 0
        input.val('')
        
        new Mealfire.Popup
          title: 'Multiplier Error'
          data: "Please enter a numerical value greater than zero."
          width: 340
          height: 125
          buttons: Mealfire.Buttons.closeOnly()
      else
        options.onChoose(mult)
        remove()
      
    box = $(options.parent).find('.section_content')
    box.css('position','relative')
    
    div = $('<div class="dropdown_menu"></div>').css
      display: 'none'
      position: 'absolute'
      top: options.top || '3px'
      right: '3px'
      width: '120px'
      zIndex: 10
      whiteSpace: 'nowrap'
    
    div.click (e) ->
      e.stopPropagation()
    
    item = $('<div class="item"></div>').css
      padding: '5px'
    
    div.append(item.append(input).append(submit))
      
    box.append(div)
    div.toggle(150)
    
    $(document.body).click ->
      remove()
      $(document.body).unbind('click', this)
    
    options.button.data("attached", true)
    e.stopPropagation() 

Mealfire.recipeURL = (id, options) ->
  url = "/recipe/$id"
  url += "?multiplier=${options.multiplier}" if options.multiplier
  return url

$.fn.placeholder = (text) ->
  el = this

  if `'placeholder' in document.createElement('input')`
    el.attr('placeholder', text)
    return
  
  if el.val() == ''
    el.val(text)
    el.addClass('placeholder')
  
  el.focus ->
    if el.val() == text
      el.val('')
      el.removeClass('placeholder')
  
  el.blur ->
    if el.val() == ''
      el.val(text)
      el.addClass('placeholder')
    
  el.closest('form').bind "submit", -> e.val('')

String.prototype.titleCase = ->
  return this.replace(/\w\S*/g, (txt) -> return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase())