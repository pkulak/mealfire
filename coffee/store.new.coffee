$ ->
  new Mealfire.FormFieldPopup
    field: $('#store_name')
    content: 'For example: "Albertsons on Coburg Rd."'
  
  new Mealfire.CategoryList '#categories', (ids) ->
    $('#category_order').val(ids)
  
  $('#delete_button').click ->
    new Mealfire.Popup
      title: "Delete Store"
      height: 125
      data: "Are you sure you want to delete this store?"
      buttons: Mealfire.Buttons.standard ->
        $.post '/store/delete', {id: store_id}, ->
          window.location = '/store'