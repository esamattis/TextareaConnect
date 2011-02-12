


do ->

    timeStamp = (new Date().getTime())
    siteId = ->
        location.href.replace(/[^a-zA-Z0-9_\-]/g, "") + "-" + timeStamp



    $.fn.uuid = ->
        e =  $(this.get(0))
        uuid = e.data("uuid")
        if uuid
            return uuid
        else
            $.fn.uuid.counter += 1
            uuid = siteId() + "-" + $.fn.uuid.counter
            e.data("uuid", uuid)
            return uuid
    $.fn.uuid.counter = 0


    $.fn.editInExternalEditor = (port) ->
        that = $(this)

        if that.data "server"
            return
        that.data "server", true

        sendToEditor = (spawn=false) ->
            port.postMessage
                textarea: that.val()
                uuid: that.uuid()
                spawn: spawn
                action: "open"

        sendToEditor(true)



textAreas = {}


port = chrome.extension.connect  name: "textareapipe"
port.onMessage.addListener (obj) ->
    textarea = textAreas[obj.uuid]
    textarea.val obj.textarea


# Listen contextmenu clicks
chrome.extension.onRequest.addListener (req, sender) ->

    if req.action is "edittextarea"

        realUrl = req.onClickData.frameUrl || req.onClickData.pageUrl
        if realUrl isnt window.location.href
            return

        textarea = $(document.activeElement)
        textAreas[textarea.uuid()] = textarea
        textarea.editInExternalEditor(port)


$(window).unload ->


    uuids =  (ta.uuid() for key, ta of textAreas)


    if uuids.length > 0
        port.postMessage
            action: "delete"
            uuids: uuids






