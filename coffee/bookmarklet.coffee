class MealfireBookmarklet
  host: 'mealfire.com'
  version: 1
  
  constructor: () ->
    if mealfireHost? then this.host = mealfireHost
    if mealfireVersion? then this.version = mealfireVersion
  
  run: () ->
    supported = false

    allElements = if document.all
      document.all
    else
      document.getElementsByTagName("body")[0].getElementsByTagName("*")

    for el in allElements
      if el.getAttribute('itemtype') == "http://data-vocabulary.org/Recipe"
        supported = true
        break
      if el.className.toLowerCase().indexOf('hrecipe') > -1
        supported = true
        break
      if el.getAttribute('typeof') == 'v:Recipe'
        supported = true
        break
    
    if supported || this.version < 2
      mealfireWindow.close() if mealfireWindow?
      
      this.buildForm "http://#{this.host}/bookmarklet/import", (form) =>
        form.appendChild(this.buildHiddenInput('html', document.body.parentNode.innerHTML))
    else
      images = []
    
      for img in document.getElementsByTagName('img')
        h = img.height
        w = img.width
        
        if h > 100 && w > 100 && w / h < 2 && h / w < 2
          images.push(img.src)
    
      this.buildForm "http://#{this.host}/bookmarklet/general_import", (form) =>
        form.target = 'mealfireImport'
        form.appendChild(this.buildHiddenInput('title', document.title))
        
        for i in [0...images.length]
          form.appendChild(this.buildHiddenInput("img_#{i}", images[i]))
      
  buildHiddenInput: (name, value) ->
    input = document.createElement('input')
    input.type = 'hidden'
    input.name = name
    input.value = value
    return input

  buildForm: (action, callback) ->
    form = document.createElement('form')
    form.method = 'post'
    form.action = action
    form.acceptCharset = 'utf8'
    
    callback(form) if callback

    form.appendChild(this.buildHiddenInput('url', window.location))

    document.body.appendChild(form)
    form.submit()

new MealfireBookmarklet().run()