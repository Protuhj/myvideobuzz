'********************************************************************
' Initializes the UDP objects for use in the application.
' @param youtube the current youtube object
'********************************************************************
Sub MulticastInit(youtube as Object)
    msgPort = createobject("roMessagePort")
    udp = createobject("roDatagramSocket")
    udp.setMessagePort(msgPort)
    addr = createobject("roSocketAddress")
    addr.setPort(6789)
    addr.SetHostName("224.0.0.115")
    udp.setAddress(addr)
    if (not(udp.setSendToAddress(addr))) then
        print ("Failed to set send to address")
        return
    end if
    ' Only local subnet
    udp.SetMulticastTTL(1)
    if (not(udp.SetMulticastLoop(false))) then
        print("Failed to disable multicast loop")
    end if
    ' Join the multicast group
    udp.joinGroup(addr)
    udp.NotifyReadable(true)
    udp.NotifyWritable(false)
    youtube.dateObj.Mark()
    youtube.udp_created = youtube.dateObj.AsSeconds()
    youtube.udp_socket = udp
    youtube.mp_socket = msgPort
End Sub

Sub UnicastInit(youtube as Object)
    msgPort = createobject("roMessagePort")
    tcp = createobject("roStreamSocket")
    tcp.setMessagePort(msgPort)
    addr = createobject("roSocketAddress")
    addr.setPort(6789)
    tcp.setAddress(addr)

    tcp.NotifyReadable(true)
    tcp.listen(1)
    if not tcp.eOK()
        print "Error creating listen socket"
        stop
    end if
    'youtube.dateObj.Mark()
    'youtube.udp_created = youtube.dateObj.AsSeconds()

    youtube.tcp_socket = tcp
    youtube.msgport_tcp = msgPort
    youtube.tcp_created = 0
End Sub

'********************************************************************
' Makes sure the UDP socket and message port stay fresh.
' FIxes an issue where the message port seemingly becomes 'stale'
' after a few hours of inactivity
' Currently, the period is one hour, which seems like a decent number
' @param youtube the current youtube object
'********************************************************************
Sub HandleStaleMessagePort( youtube as Dynamic )
    youtube.dateObj.Mark()
    ' Re-initialize the socket and message port every hour to avoid a stale message port
    if ( ( youtube.dateObj.AsSeconds() - youtube.udp_created ) > 3600 ) then
        youtube.udp_socket.Close()
        youtube.mp_socket = invalid
        MulticastInit( youtube )
    end if
End Sub

'********************************************************************
' Determines if someone on the network has tried to query for other videos on the LAN
' Listens for active video queries, and responds if necessary
'********************************************************************
Sub CheckForMCast()
    youtube = getYoutube()
    if (youtube.mp_socket = invalid OR youtube.udp_socket = invalid) then
        print("CheckForMCast: Invalid Message Port or UDP Socket")
        return
    end if

    message = youtube.mp_socket.GetMessage()
    ' Flag to track if a response is necessary -- we only want to respond once,
    ' even if we find multiple queries available on the socket
    mvbRespond = false
    while (message <> invalid)
        if (type(message) = "roSocketEvent") then
            data = youtube.udp_socket.receiveStr(4096) ' max 4096 characters

            ' Replace newlines
            data = youtube.regexNewline.ReplaceAll( data, "" )
            ' print("Received " + Left(data, 2) + " from " + Mid(data, 3))
            if ((Left(data, 2) = "1?") AND (Mid(data, 3) <> youtube.device_id)) then
                ' Nothing to do if there's no video to watch
                if (youtube.history <> invalid AND youtube.history.Count() > 0) then
                    mvbRespond = true
                end if
            else if ((Left(data, 2) = "2:")) then ' Allow push of videos from other sources on the LAN (not implemented within this source)
                remainder = Mid(data, 3)
                print("Received force: " + remainder)
                handleYouTubePush( remainder )
            else if ((Left(data, 3) = "99:")) then ' Force-play of direct URL
                remainder = Mid(data, 4)
                print("Received force 99: " + remainder)
                handleDirectURLPush( remainder )
            else if ((Left(data, 2) = "1:")) then
                ' print("Received udp response: " + Mid(data, 3))
            end if
        end if
        ' This effectively drains the receive queue
        message = wait(10, youtube.mp_socket)
    end while
    if (mvbRespond = true) then
        json = SimpleJSONBuilder(youtube.history[0])
        if (json <> invalid) then
            ' Replace all newlines in the JSON
            json = youtube.regexNewline.ReplaceAll(json, "")
            youtube.udp_socket.SendStr("1:" +  json)
        end if
    end if
    ' Determine if the udp socket and message port need to be re-initialized
    HandleStaleMessagePort( youtube )
End Sub

'********************************************************************
' Determines if there has been a connection on the TCP port (6789) used
' to serve the DASH manifest to play adaptive formats
'********************************************************************
Sub CheckForUnicast()
    rn = Chr(13) + Chr(10)
    youtube = getYoutube()
    if (youtube.msgport_tcp = invalid OR youtube.tcp_socket = invalid) then
        print("CheckForUnicast: Invalid Message Port or TCP Socket")
        return
    end if
    tcpListen = youtube.tcp_socket
    connections = youtube.connections
    messagePort = youtube.msgport_tcp
    buffer = youtube.buffer
    message = youtube.msgport_tcp.GetMessage()

    text = youtube.dashManifestContents
    if ( text = invalid or len( text ) = 0 ) then
        return
    end if
    'print "MPD is this many bytes: " + toStr( len ( text ) )
    while (message <> invalid)
        if (type(message) = "roSocketEvent") then
            changedID = message.getSocketID()
            if (changedID = tcpListen.getID() and tcpListen.isReadable()) then
                ' New
                newConnection = tcpListen.accept()
                if (newConnection = Invalid) then
                    print "accept failed"
                else
                    ' print "accepted new connection " newConnection.getID()
                    newConnection.notifyReadable(true)
                    newConnection.setMessagePort(messagePort)
                    connections[Stri(newConnection.getID())] = newConnection
                end if
            else
                ' Activity on an open connection
                connection = connections[Stri(changedID)]
                if (connection <> invalid) then
                    closed = false
                    if (connection.isReadable()) then
                        received = connection.receive(buffer, 0, 512)
                        'print "received is " received
                        if (received > 0) then
                            if ( connection.isWritable() ) then
                                response = "HTTP/1.1 200 OK" + rn
                                'response += "Date: Wed, 24 Jan 2018 05:04:22 GMT" + rn
                                response += "Content-Type: text/html; charset=UTF-8" + rn
                                response += "Content-Length: " + toStr( len( text ) ) + rn
                                response += "Accept-Ranges: bytes" + rn
                                response += "Connection: close" + rn + rn
                                response += text
                                sent = connection.sendStr(response)
                                print "Sent " + tostr(sent) + " bytes"
                            else
                            print "Socket not writeable!"
                            end if
                            'closed = true
                        else if (received = 0) then
                            ' client closed
                            closed = true
                        end if
                    end if
                    if (closed or not connection.eOK()) then
                        print "closing connection " changedID
                        connection.close()
                        connections.delete(Stri(changedID))
                    end if
                end if
            end if
        end if
        ' This effectively drains the receive queue
        message = wait(10, youtube.msgport_tcp)
    end while
End Sub

Sub handleYouTubePush( youtubeID as String )
    youtube = getYoutube()
    tokens = strTokenize( youtubeID, ";" )
    if ( tokens.Count() = 2 ) then
        'print "My device ID: " ; youtube.device_id
        if (youtube.device_id = tokens[0]) then
            ids = []
            ids.push(tokens[1])

            res = youtube.ExecBatchQueryV3( ids )
            videos = youtube.newVideoListFromJSON( res.items )
            if (videos.Count() > 0) then
            
                metadata = GetVideoMetaData( videos )
                if (metadata.Count() > 0) then
                
                    theVideo = metadata[0]
                    result = video_get_qualities(theVideo)
                    if (result = 0) then
                        DisplayVideo(theVideo)
                    end if
                else
                    problem = ShowDialogNoButton( "", "Having trouble finding a Roku-compatible stream..." )
                    sleep( 3000 )
                    problem.Close()
                end if
            else
                problem = ShowDialogNoButton( "", "Invalid, or deleted video pushed." )
                sleep( 3000 )
                problem.Close()
            end if
        end if
        print "Roku ID: " ; tokens[0]
        print "Video ID: " ; tokens[1]
    end if
End Sub

Sub handleDirectURLPush( URL as String )
     youtube = getYoutube()
    tokens = strTokenize( URL, ";" )
    if ( tokens.Count() = 2 ) then
        'print "My device ID: " ; youtube.device_id
        if (youtube.device_id = tokens[0]) then
            metaD = newForcedVideo(tokens[1])
            if (metaD <> invalid) then
                DisplayVideo(metaD)
            else
                print "Failed to set video type for " ; tokens[1]
            end if
        end if
        print "Roku ID: " ; tokens[0]
        print "Video ID: " ; tokens[1]
    end if
End Sub

Function newForcedVideo(URL as String) as Dynamic

    constants = getConstants()
    meta = CreateObject("roAssociativeArray")
    meta.ContentType = "movie"

    meta["ID"]                     = "fake"
    meta["Author"]                 = "Unknown"
    meta["TitleSeason"]            = "Unknown"
    meta["Title"]                  = "Forced play from external source."
    meta["Description"]            = "Received from external source."
    meta["Length"]                 = 0
    if (right(lcase(URL), 4) = "m3u8") then
        meta["StreamFormat"]           = "hls"
    else if (right(lcase(URL), 3) = "mp4") then
        meta["StreamFormat"]           = "mp4"
    else
        vidType = GetForcedTypeSuggestion()
        if (vidType <> "") then
            meta["StreamFormat"] = vidType
        else
            return invalid
        end if
    end if
    meta["Live"]                   = false
    meta["Streams"]                = []
    meta["Streams"].Push( {url: URL, bitrate: 512, quality: false, contentid: "fake"} )
    meta["Linked"]                 = ""
    meta["Source"]                 = "External"
    meta["BookmarkPosition"]       = 0
    'meta["SwitchingStrategy"]      = "no-adaptation"
    'PrintAA(meta)
    return meta
End Function

Function GetForcedTypeSuggestion() as String
    dialog = CreateObject("roMessageDialog")
    port = CreateObject("roMessagePort")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Received Video Push")
    dialog.SetText("Unable to detect video type, what should it be treated as?")
    dialog.EnableBackButton(true)
    dialog.SetMenuTopLeft( true )
    dialog.addButton(1, "Mp4")
    dialog.addButton(2, "HLS (m3u8)")
    dialog.addButton(3, "Cancel")
    dialog.Show()
    ret = ""
    while true
        dlgMsg = wait(2000, dialog.GetMessagePort())
        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isButtonPressed()) then
                if (dlgMsg.GetIndex() = 1) then
                    dialog.Close()
                    ret = "mp4"
                    exit while
                else if (dlgMsg.GetIndex() = 2) then
                    dialog.Close()
                    ret = "hls"
                    exit while
                else if (dlgMsg.GetIndex() = 3) then
                    dialog.Close()
                    exit while
                end if
            else if (dlgMsg.isScreenClosed()) then
                dialog.Close()
                exit while
            else
                ' print ("Unhandled msg type")
                exit while
            end if
        else if (dlgMsg = invalid) then
            CheckForMCast()
        else
            ' print ("Unhandled msg: " + type(dlgMsg))
            exit while
        end if
    end while
    print "User selected: " ; ret
    return ret
End Function


'********************************************************************
' Determines if there are available videos on the LAN to continue watching
' Multicasts a query for other listening devices to respond with their currently-active video
' This function is a callback handler for the main menu
' @param youtube the current youtube object
'********************************************************************
Sub CheckForLANVideos(youtube as Object)
    jsonMetadata = []
    if (youtube.mp_socket = invalid OR youtube.udp_socket = invalid) then
        print("CheckForMCast: Invalid Message Port or UDP Socket")
        return
    end if
    dialog = ShowPleaseWait("Searching for videos on your LAN")
    ' Multicast query
    youtube.udp_socket.SendStr("1?" + youtube.device_id)
    ' Wait a maximum of 5 seconds for a response
    t = CreateObject("roTimespan")
    message = wait(2500, youtube.mp_socket)
    while (message <> invalid OR t.TotalSeconds() < 5)
        if (type(message) = "roSocketEvent") then
            data = youtube.udp_socket.receiveStr(4096) ' max 4096 characters
            ' print("Received " + Left(data, 2) + " from " + Mid(data, 3))
            ' Replace newlines -- this WILL screw up JSON parsing
            data = youtube.regexNewline.ReplaceAll( data, "" )
            if ((Left(data, 2) = "1:")) then
                response = Mid(data, 3)
                ' print("Received udp response: " + response)
                jsonObj = ParseJson(response)
                if (jsonObj <> invalid) then
                    foundInList = false
                    for each vid in jsonMetadata
                        if ( vid["ID"] = jsonObj["ID"] ) then
                            foundInList = true
                            exit for
                        end if
                    end for
                    if (not(foundInList)) then
                        jsonMetadata.Push(jsonObj)
                    end if
                end if
            end if
        ' else the message is invalid
        end if
        ' If we continue to receive valid roSocketEvent messages, we still want to limit the query to 5 seconds
        if (t.TotalSeconds() > 5 OR jsonMetadata.Count() > 50) then
            exit while
        end if
        message = wait(100, youtube.mp_socket)
    end while
    print("Found " + tostr(jsonMetadata.Count()) + " LAN Videos")
    dialog.Close()
    youtube.DisplayVideoListFromMetadataList(jsonMetadata, "LAN Videos", invalid, invalid, invalid)
End Sub
