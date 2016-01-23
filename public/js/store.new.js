$(function() {
  new Mealfire.FormFieldPopup({
    field: $('#store_name'),
    content: 'For example: "Albertsons on Coburg Rd."'
  });
  new Mealfire.CategoryList('#categories', function(ids) {
    return $('#category_order').val(ids);
  });
  return $('#delete_button').click(function() {
    return new Mealfire.Popup({
      title: "Delete Store",
      height: 125,
      data: "Are you sure you want to delete this store?",
      buttons: Mealfire.Buttons.standard(function() {
        return $.post('/store/delete', {
          id: store_id
        }, function() {
          return window.location = '/store';
        });
      })
    });
  });
});