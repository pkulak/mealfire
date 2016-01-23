var directions_editor = null;

$(function() {
  $('#new_tag_submit').click(createTag);
  
  $('#new_tag_input').keypress(function(e) {
    var code = (e.keyCode ? e.keyCode : e.which);
    if (code == 13) {
      createTag();
      e.stopPropagation();
    }
  });
  
  $('#public-private-checkbox').change(function() {
    if ($(this).is(':checked'))
      $.post('/recipe/make_public', {id: recipe_id});
    else
      $.post('/recipe/make_private', {id: recipe_id});
  });
  
  $('#show-hide-checkbox').change(function() {
    if ($(this).is(':checked'))
      $.post('/recipe/unhide', {id: recipe_id});
    else
      $.post('/recipe/hide', {id: recipe_id});
  });
  
  Mealfire.multiplierButton({
    button: '#custom-multiplier',
    parent: '#ingredients',
    current: multiplier,
    onChoose: function(mult) {
      window.location = '/recipe/' + recipe_id + '?multiplier=' + mult;
    }
  });
});

function highlightNewIngredients() {
  $('#ingredient_holder .highlight').effect("highlight", {}, 3000);
}

function getPrevious(el) {
  var curPrevious = null;
  var elPrevious = null;
  
  $(el).closest('ul').find('li.ingredient').each(function() {
    if (this == $(el)[0])
      elPrevious = curPrevious;
    
    curPrevious = $(this).data('ingredient-id');
  });
  
  return elPrevious;
}

function getPreviousGroup(el) {
  var curPrevious = null;
  var elPrevious = null;
  
  $('#ingredient_holder ul.group').each(function() {
    if (this == $(el)[0])
      elPrevious = curPrevious;
    
    curPrevious = $(this).attr('id').split('_')[1]
  });
  
  return elPrevious;
}

function changeTitle() {
  new Mealfire.Popup({
	  width: 400,
	  height: 140,
	  title: "Change Title",
	  url: '/recipe/edit_title/' + recipe_id,
	  buttons: Mealfire.Buttons.standard(function(popup) {
	    var data = {title: $("#recipe_edit_box").val()};
	    $.post("/recipe/edit_title/" + recipe_id, data, function(data) {
	      popup.close();
	      $("#recipe_title_header").text(data);
	    });
	  })
	});
}

function createTag() {
  var data = {name: $('#new_tag_input').val()};
  
  $.ajax({
    url: '/recipe/add_tag/' + recipe_id,
    data: data,
    success: function(data) {
      $('#tags_holder').html(data)
    },
    error: function(req) {
      new Mealfire.Popup({
        height: 125,
        title: 'Error',
        data: req.responseText,
        buttons: Mealfire.Buttons.closeOnly()
      })
    }
  });

  $('#new_tag_input').val('');
}

function deleteIngredient(id) {
  $.post("/recipe/delete_ingredient/" + id, null, function() {
    $('#ingredient_holder').load('/recipe/_ingredient_list/' +  recipe_id);
  });
}

function deleteTag(id) {
  $.post("/recipe/delete_tag/" + id, null, function(data) {
    $('#tags_holder').html(data);
  });
}

function editIngredient(id) {
  new Mealfire.Popup({
	  width: 400,
	  height: 140,
	  title: "Edit Ingredient",
	  url: '/recipe/edit_ingredient/' + id,
	  buttons: Mealfire.Buttons.standard(function(popup) {
      $.ajax({
        url: "/recipe/edit_ingredient/" + id,
        data: {text: $("#ingredient_edit_box").val()},
        type: 'POST',
        success: function(data) {
          popup.close();
  	      $('#ingredient_holder').html(data);
  	      highlightNewIngredients();
        }
      });
    })
  })
}

function promoteIngredient(id) {
  $.ajax({
    url: '/recipe/promote_ingredient',
    data: {id: id},
    type: 'POST',
    success: function(data) {
      $('#ingredient_holder').html(data);
    }
  })
}

function demoteGroup(id) {
  $.ajax({
    url: '/recipe/demote_group',
    data: {id: id},
    type: 'POST',
    success: function(data) {
      $('#ingredient_holder').html(data);
    }
  })
}

function deleteIngredientGroup(id) {
  $.post("/recipe/delete_ingredient_group/" + id, null, function(){
    $('#ingredient_holder').load('/recipe/_ingredient_list/' +  recipe_id);
  });
}

function editIngredientGroup(id) {
  new Mealfire.Popup({
	  width: 400,
	  height: 140,
	  title: "Edit Divider",
	  url: '/recipe/edit_ingredient_group/' + id,
	  buttons: Mealfire.Buttons.standard(function(popup) {
	    var data = {text: $("#ingredient_group_edit_box").val()};

	    $.post("/recipe/edit_ingredient_group/" + id, data, function(data) {
	      popup.close();
	      $('#ingredient_holder').html(data);
	      highlightNewIngredients();
	    });
    })
  })
}

function addIngredients(group_id) {
  new Mealfire.Popup({
	  width: 400,
	  height: 300,
	  title: "Add Ingredients",
	  url: '/recipe/add_ingredients/' + recipe_id,
	  buttons: Mealfire.Buttons.standard(function(popup) {
	    var data = {text: $("#ingredients_input").val(), group_id: group_id || null}
	    $.post('/recipe/add_ingredients/' + recipe_id, data, function(data) {
	      popup.close();
	      $('#ingredient_holder').html(data);
	      highlightNewIngredients();
	    });
	  })
	});
}

function addDivider() {
  new Mealfire.Popup({
	  width: 400,
	  height: 140,
	  title: "Add Divider",
	  url: '/recipe/add_ingredient_group/' + recipe_id,
	  buttons: Mealfire.Buttons.standard(function(popup) {
	    var data = {text: $("#ingredient_group_input").val()}
	    $.post('/recipe/add_ingredient_group/' + recipe_id, data, function(data) {
	      popup.close();
	      $('#ingredient_holder').html(data);
	      highlightNewIngredients();
	    });
	  })
	})
};

function addChangeImage() {
  new Mealfire.Popup({
    width: 400,
    height: 140,
    title: "Add Image",
    url: '/recipe/add_image/' + recipe_id,
    buttons: Mealfire.Buttons.standard(),
    form_params: {
      method: 'post',
      enctype: 'multipart/form-data',
      acceptCharset: 'utf8',
      action: '/recipe/add_image/' + recipe_id}
  });
}

function addDirections() {
  // I can't use jQuery to create this element for some reason.
  var textarea = document.createElement('textarea');
  textarea.id = 'directions_input';
  textarea.value = $.trim($('#directions_holder').html());
  
  var title = null;
  
  if ($('#add_directions_button').text() == 'edit directions') {
    title = "Edit Directions";
  } else {
    title = "Add Directions";
  }
  
  new Mealfire.Popup({
	  width: 600,
	  height: 375,
	  title: title,
	  data: textarea,
	  buttons: [Mealfire.Buttons.close, {
	      text: 'Submit',
	      click: function(popup) {
	        var data = {text: $("#directions_input").html()}
    	    $.post('/recipe/edit_directions/' + recipe_id, data, function(data) {
    	      popup.close();
    	      $('#directions_holder').html(data);
    	      $('#add_directions_button').text('edit directions');
    	    });
    	    popup.loading();
          return false;
	      }
	    }
	  ],
    complete: setupEditor
  });
}

function deleteRecipe() {
  new Mealfire.Popup({
    title: "Delete Recipe",
    height: 125,
    width: 350,
    data: "Are you sure you want to delete this recipe? This <strong>cannot</strong> be undone!",
    buttons: [Mealfire.Buttons.cancel, {
      text: 'Delete Recipe',
      click: function(popup) {
        $.post("/recipe/delete", {id: recipe_id}, function() {
          window.location = '/recipe';
        })
        popup.loading();
        return false;
      }
    }]
  });
}

function removeImage() {
  $.get('/recipe/remove_image/' + recipe_id, {}, function(data) {
    $('#recipe_image').remove();
    $('#buttons_holder').html(data);
  })
}

function setupEditor() {
  $('#directions_input').tinymce({
		script_url: '/js/tiny_mce/tiny_mce.js',
		theme: "advanced",
    mode: "exact",
    content_css : "/css/screen.css",
    theme_advanced_buttons1: "fontsizeselect,bold,italic,underline,bullist,numlist,undo,redo,code",
    theme_advanced_buttons2: "",
    theme_advanced_buttons3: "",
    theme_advanced_font_sizes: "Tiny=10px,Normal=12px,Large=16px"
	});
}

function setupIngredients() {
  $('ul.group').sortable({
    cursor: 'move',
    items: '.ingredient',
    connectWith: 'ul.group',
    update: function(event, ui) {
      // Send the update back to the server.
      data = {
        ingredient_id: $(ui.item).data('ingredient-id'),
        new_group_id: $(ui.item).closest('ul').attr('id').split('_')[1],
        previous_id: getPrevious(ui.item)
      }
      
      $.post('/recipe/move_ingredient', data);
    }
  });
  
  $('#ingredient_holder').sortable({
    cursor: 'move',
    items: 'ul.group',
    update: function(event, ui) {
      data = {
        group_id: $(ui.item).attr('id').split('_')[1],
        previous_id: getPreviousGroup(ui.item)
      }
      
      $.post('/recipe/move_group', data);
    }
  });
  
  var multiplier = $.url.param('multiplier')
  
  if (multiplier && multiplier != 1) {
    $('.ingredient img.dropdown, .ingredient_group img.dropdown').each(function() {
      new Mealfire.Dropdown({
        element: $(this),
        parent: $(this).closest('li'),
        width: 190,
        items: [{
          text: 'View Original Amount to Edit',
          click: function() {
            window.location = '/recipe/' + recipe_id
          }
        }]
      })
    });
    
    return;
  }
  
  $('.ingredient img.dropdown').each(function() {
    var id = this.id.split('_')[1];
    
    new Mealfire.Dropdown({
      element: $(this),
      parent: $(this).closest('li'),
      items: [{
        text: 'Remove',
        click: function() {
          deleteIngredient(id);
        }
      },{
        text: 'Edit',
        click: function() {
          editIngredient(id);
        }
      },{
        text: 'Make Divider',
        click: function() {
          promoteIngredient(id);
        }
      }]
    })
  });
  
  $('.ingredient_group img.dropdown').each(function() {
    var id = this.id.split('_')[1];
    
    new Mealfire.Dropdown({
      element: $(this),
      parent: $(this).closest('div'),
      width: 125,
      items: [{
        text: 'Remove',
        click: function() {
          deleteIngredientGroup(id);
        }
      }, {
        text: 'Edit',
        click: function() {
          editIngredientGroup(id);
        }
      }, {
        text: 'Add Ingredients',
        click: function() {
          addIngredients(id);
        }
      }, {
        text: "Make Ingredient",
        click: function() {
          demoteGroup(id);
        }
      }]
    });
  });
}

function sharingFailMessage() {
  new Mealfire.Popup({
    title: "Feature Unavailable",
    height: 125,
    width: 350,
    data: 'Sorry, only registered users can share a recipe.',
    buttons: Mealfire.Buttons.closeOnly()
  });
}

function shareRecipe() {
  if (!authed_user) {
    sharingFailMessage();
    return false;
  }
  
  new Mealfire.Popup({
    title: "Share Recipe",
    height: 350,
    width: 375,
    data: 'Please enter the email address of the person with whom you\'d like to share this recipe:' +
      '<input style="display:block;margin:10px 0;width:98%;" type="text" id="share_email" name="email"/> ' +
      'And, optionally, a personal message: ' +
      '<textarea style="display:block;margin-top:10px;height:150px;width:98%;" id="share_message"></textarea>',
    buttons: Mealfire.Buttons.standard(function(popup) {
      var email = $('#share_email').val()
      
      var data = {
        email: email,
        message: $('#share_message').val()
      }
      
      $.post("/recipe/share/" + recipe_id, data, function(body) {
        if (body == 'success') {
          popup.closeNow();
          
          new Mealfire.DynamicPopup({
            title: "Done!",
            width: 400,
            data: "An email has been sent to " + email + " with a link to your recipe.",
            buttons: Mealfire.Buttons.closeOnly()
          });
        }
      });
    }, "Share Recipe")
  });
}

function shareFacebook() {
  if (!authed_user) {
    sharingFailMessage();
    return false;
  }
  
  var shareWindow = window.open('http://mealfire.com/bookmarklet/loading','facebook-share','toolbar=0,status=0,resizable=1,width=625,height=370');
  
  $.ajax({
    url: '/recipe/get_share_url',
    data: {id: recipe_id, recipient: 'Facebook'},
    success: function(url) {
      shareWindow.location = 'http://www.facebook.com/sharer.php?u=' + escape(url) + '&t=' + escape(recipeName);
    }
  });
}

function shareLink() {
  if (!authed_user) {
    sharingFailMessage();
    return false;
  }
  
  $.ajax({
    url: '/recipe/get_share_url',
    data: {id: recipe_id, recipient: 'Link'},
    success: function(url) {
      var data = $('<div><p class="first">You can use the link below to share this recipe:</p></div>')
        .append($('<input type="text" style="width:98%;" readonly>').val(url))
      
      new Mealfire.Popup({
        title: "Share Recipe Link",
        height: 150,
        width: 375,
        data: data,
        buttons: Mealfire.Buttons.closeOnly()
      });
    }
  });
}

function printRecipe() {
  var multiplier = $.url.param('multiplier')
  
  if (multiplier && multiplier != '1')
    window.location = '/recipe/print/' + recipe_id + '?multiplier=' + multiplier;
  else
    window.location = '/recipe/print/' + recipe_id;
}