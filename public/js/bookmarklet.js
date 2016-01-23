var MealfireBookmarklet;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
MealfireBookmarklet = (function() {
  MealfireBookmarklet.prototype.host = 'mealfire.com';
  MealfireBookmarklet.prototype.version = 1;
  function MealfireBookmarklet() {
    if (typeof mealfireHost !== "undefined" && mealfireHost !== null) {
      this.host = mealfireHost;
    }
    if (typeof mealfireVersion !== "undefined" && mealfireVersion !== null) {
      this.version = mealfireVersion;
    }
  }
  MealfireBookmarklet.prototype.run = function() {
    var allElements, el, h, images, img, supported, w, _i, _j, _len, _len2, _ref;
    supported = false;
    allElements = document.all ? document.all : document.getElementsByTagName("body")[0].getElementsByTagName("*");
    for (_i = 0, _len = allElements.length; _i < _len; _i++) {
      el = allElements[_i];
      if (el.getAttribute('itemtype') === "http://data-vocabulary.org/Recipe") {
        supported = true;
        break;
      }
      if (el.className.toLowerCase().indexOf('hrecipe') > -1) {
        supported = true;
        break;
      }
      if (el.getAttribute('typeof') === 'v:Recipe') {
        supported = true;
        break;
      }
    }
    if (supported || this.version < 2) {
      if (typeof mealfireWindow !== "undefined" && mealfireWindow !== null) {
        mealfireWindow.close();
      }
      return this.buildForm("http://" + this.host + "/bookmarklet/import", __bind(function(form) {
        return form.appendChild(this.buildHiddenInput('html', document.body.parentNode.innerHTML));
      }, this));
    } else {
      images = [];
      _ref = document.getElementsByTagName('img');
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        img = _ref[_j];
        h = img.height;
        w = img.width;
        if (h > 100 && w > 100 && w / h < 2 && h / w < 2) {
          images.push(img.src);
        }
      }
      return this.buildForm("http://" + this.host + "/bookmarklet/general_import", __bind(function(form) {
        var i, _ref2, _results;
        form.target = 'mealfireImport';
        form.appendChild(this.buildHiddenInput('title', document.title));
        _results = [];
        for (i = 0, _ref2 = images.length; 0 <= _ref2 ? i < _ref2 : i > _ref2; 0 <= _ref2 ? i++ : i--) {
          _results.push(form.appendChild(this.buildHiddenInput("img_" + i, images[i])));
        }
        return _results;
      }, this));
    }
  };
  MealfireBookmarklet.prototype.buildHiddenInput = function(name, value) {
    var input;
    input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    return input;
  };
  MealfireBookmarklet.prototype.buildForm = function(action, callback) {
    var form;
    form = document.createElement('form');
    form.method = 'post';
    form.action = action;
    form.acceptCharset = 'utf8';
    if (callback) {
      callback(form);
    }
    form.appendChild(this.buildHiddenInput('url', window.location));
    document.body.appendChild(form);
    return form.submit();
  };
  return MealfireBookmarklet;
})();
new MealfireBookmarklet().run();