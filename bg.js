(function() {
  var Connection, initExtension, loadSocketIO, showTempNotification;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  localStorage.host = localStorage.host || "localhost";
  localStorage.port = localStorage.port || 32942;
  window.connection = null;
  loadSocketIO = function() {
    clearTimeout(loadSocketIO.timer);
    console.log("trying to get io from " + localStorage.host + ":" + localStorage.port);
    if (!window.io) {
      jQuery.getScript("http://" + localStorage.host + ":" + localStorage.port + "/socket.io/socket.io.js", function() {
        window.connection = new Connection(localStorage.host, localStorage.port);
        initExtension();
        return clearTimeout(loadSocketIO.timer);
      });
      return loadSocketIO.timer = setTimeout(loadSocketIO, 500);
    } else {
      return console.log("we aleready have io");
    }
  };
  initExtension = function() {
    chrome.contextMenus.create({
      title: "Edit in external editor",
      contexts: ["all", "editable", "page"],
      onclick: function(onClickData, tab) {
        return chrome.tabs.sendRequest(tab.id, {
          action: "edittextarea",
          onClickData: onClickData
        });
      }
    });
    return chrome.extension.onConnect.addListener(function(port) {
      if (port.name !== "textareapipe") {
        return;
      }
      return port.onMessage.addListener(function(msg) {
        return connection.pageActions[msg.action](port, msg);
      });
    });
  };
  showTempNotification = function(msg) {
    var notification;
    notification = webkitNotifications.createNotification("icon.png", 'TextAreaConnect', msg);
    notification.show();
    return setTimeout(function() {
      return notification.cancel();
    }, 5000);
  };
  Connection = (function() {
    function Connection(host, port) {
      this.host = host;
      this.port = port;
      this.ports = {};
      this.socket = null;
      this.pageActions = {
        open: __bind(function(port, msg) {
          this.ports[msg.uuid] = port;
          msg.type = msg.type || "txt";
          return this.send(msg);
        }, this),
        "delete": __bind(function(port, msg) {
          var uuid, _i, _len, _ref;
          _ref = msg.uuids;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            uuid = _ref[_i];
            delete this.ports[uuid];
          }
          return this.send(msg);
        }, this)
      };
      this.initSocket();
      console.log("creating new socket " + this.host + ":" + this.port);
    }
    Connection.prototype.initSocket = function() {
      var _ref;
      if ((_ref = this.socket) != null) {
        _ref.disconnect();
      }
      this.socket = new io.Socket(this.host, {
        port: this.port
      });
      this.socket.on("message", __bind(function(msg) {
        var obj, port;
        obj = JSON.parse(msg);
        port = this.ports[obj.uuid];
        return port.postMessage(obj);
      }, this));
      this.socket.on("connect", __bind(function() {
        console.log("stopping connection poller");
        clearTimeout(this.reconnectTimer);
        return showTempNotification("Connected to TextAreaServer at " + this.socket.transport.socket.URL);
      }, this));
      this.socket.on("disconnect", __bind(function() {
        showTempNotification("Disconnected from TextAreaServer at " + this.socket.transport.socket.URL);
        return this._reConnect();
      }, this));
      return this.socket.connect();
    };
    Connection.prototype.send = function(obj) {
      return this.socket.send(JSON.stringify(obj));
    };
    Connection.prototype._reConnect = function() {
      var _ref, _ref2, _ref3;
      console.log("Trying to connect to " + ((_ref = this.socket.transport) != null ? (_ref2 = _ref.socket) != null ? _ref2.URL : void 0 : void 0));
      if (!((_ref3 = this.socket) != null ? _ref3.connected : void 0)) {
        this.socket.connect();
      }
      clearTimeout(this.reconnectTimer);
      return this.reconnectTimer = setTimeout(__bind(function() {
        return this._reConnect();
      }, this), 2000);
    };
    return Connection;
  })();
  loadSocketIO();
}).call(this);
