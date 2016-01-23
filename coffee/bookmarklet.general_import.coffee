$ ->
  $('#photos li').click ->
    $(this).addClass('selected')
    $(this).siblings().removeClass('selected')
    $('#photo').val($(this).find('img').attr('src'))
  
  # Setup the editor
  $('#directions').tinymce
    script_url: "/js/tiny_mce/tiny_mce.js"
    theme: "advanced"
    mode: "exact"
    content_css: "/css/screen.css"
    theme_advanced_buttons1: "fontsizeselect,bold,italic,underline,bullist,numlist,undo,redo,code"
    theme_advanced_buttons2: ""
    theme_advanced_buttons3: ""
    theme_advanced_font_sizes: "Tiny=10px,Normal=12px,Large=16px"