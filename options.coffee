


window.onload = ->

    # Load previous settings
    for key, value of localStorage
        $("##{key}").val value

    bkg = chrome.extension.getBackgroundPage()

    $("#save").click ->
        $(".setting").each ->

            e = $(this)
            setting = e.attr("id")
            value = e.val()

            localStorage[setting] = value
            bkg.connection?[setting] = value

        bkg.connection?.initSocket()

        return this


