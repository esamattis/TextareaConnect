(function() {
  window.onload = function() {
    var bkg, key, value;
    for (key in localStorage) {
      value = localStorage[key];
      $("#" + key).val(value);
    }
    bkg = chrome.extension.getBackgroundPage();
    return $("#save").click(function() {
      var _ref;
      $(".setting").each(function() {
        var e, setting, _ref;
        e = $(this);
        setting = e.attr("id");
        value = e.val();
        localStorage[setting] = value;
        return (_ref = bkg.connection) != null ? _ref[setting] = value : void 0;
      });
      if ((_ref = bkg.connection) != null) {
        _ref.initSocket();
      }
      return this;
    });
  };
}).call(this);
