


localStorage.host = localStorage.host or "localhost"
localStorage.port = localStorage.port or 32942

window.connection = null

loadSocketIO = ->
    clearTimeout loadSocketIO.timer
    console.log "trying to get io from #{ localStorage.host }:#{ localStorage.port }"
    if not window.io
        jQuery.getScript "http://#{ localStorage.host }:#{ localStorage.port }/socket.io/socket.io.js", ->
            window.connection = new Connection(localStorage.host, localStorage.port)
            initExtension()
            clearTimeout loadSocketIO.timer

        # TODO: Real error handling with real ajax calls
        loadSocketIO.timer = setTimeout loadSocketIO, 500
    else
        console.log "we aleready have io"



initExtension = ->

    chrome.contextMenus.create
        title: "Edit in external editor"
        contexts: ["all", "editable", "page"]
        onclick: ( onClickData, tab ) ->
            chrome.tabs.sendRequest tab.id, action: "edittextarea", onClickData: onClickData


    chrome.extension.onConnect.addListener (port) ->
        if port.name isnt "textareapipe"
            return

        port.onMessage.addListener (msg)  ->
            connection.pageActions[msg.action](port, msg)







showTempNotification = (msg) ->

    notification = webkitNotifications.createNotification "icon.png", 'TextAreaConnect', msg

    notification.show()
    setTimeout ->
        notification.cancel()
    , 5000



class Connection

    constructor: (@host, @port) ->
        @ports = {}
        @socket = null
        @pageActions =
            open: (port, msg) =>
                @ports[msg.uuid] = port
                msg.type = msg.type or "txt"
                @send msg

            delete: (port, msg) =>
                for uuid in msg.uuids
                    delete @ports[uuid]
                @send msg

        @initSocket()
        console.log "creating new socket #{@host}:#{@port}"

    initSocket: ->


        @socket?.disconnect()


        @socket = new io.Socket @host, port: @port

        @socket.on "message", (msg) =>
            obj = JSON.parse msg
            port = @ports[obj.uuid]
            port.postMessage obj


        @socket.on "connect", =>
            console.log "stopping connection poller"
            clearTimeout @reconnectTimer
            showTempNotification "Connected to TextAreaServer at #{ @socket.transport.socket.URL }"

        @socket.on "disconnect", =>
            showTempNotification "Disconnected from TextAreaServer at #{ @socket.transport.socket.URL }"
            @_reConnect()

        @socket.connect()

    send: (obj) ->
        @socket.send JSON.stringify obj


    _reConnect: ->

        console.log "Trying to connect to #{ @socket.transport?.socket?.URL }"

        if not @socket?.connected
            @socket.connect()

        clearTimeout @reconnectTimer

        # Retry
        @reconnectTimer = setTimeout =>
            @_reConnect()
        , 2000







loadSocketIO()
