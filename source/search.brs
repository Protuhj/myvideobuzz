'********************************************************************
' YouTube Search
'********************************************************************
Sub SearchYouTube_impl()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSearchScreen")
    screen.SetMessagePort(port)

    history = CreateObject("roSearchHistory")
    screen.SetSearchTerms(history.GetAsArray())
    screen.SetBreadcrumbText("", "Hit the * button for search options")
    screen.Show()
    parms = {}
    while (true)
        msg = wait(2000, port)
        if (type(msg) = "roSearchScreenEvent") then
            'print "Event: "; msg.GetType(); " msg: "; msg.GetMessage()
            if (msg.isScreenClosed()) then
                return
            else if (msg.isPartialResult()) then
                screen.SetSearchTermHeaderText("Suggestions:")
                screen.SetClearButtonEnabled(false)
                screen.SetSearchTerms(GenerateSearchSuggestions(msg.GetMessage()))
            else if (msg.isFullResult()) then
                keyword = msg.GetMessage()
                parms["q"] = keyword
                prompt = "Searching YouTube for " + Quote() + keyword + Quote()
                if (m.searchLengthFilter <> "") then
                    parms["videoDuration"] = LCase(m.searchLengthFilter)
                    prompt = prompt + Chr(10) + "Length: " + m.searchLengthFilter
                end if
                if (m.searchSort <> "") then
                    parms["order"] = LCase(m.searchSort)
                    prompt = prompt + Chr(10) + "Sort: " + GetSortText(m.searchSort)
                end if
                ' Don't include items that require purchase to watch, since we don't have a way to pay for them!
                parms["safeSearch"] = "none"
                'dialog = ShowPleaseWait("Please wait", prompt)
                'videos = m.DoSearch( parms )
                'if (videos <> invalid AND videos.Count() > 0) then
                history.Push(keyword)
                screen.AddSearchTerm(keyword)
                'dialog.Close()
                    'm.DisplayVideoListFromVideoList(videos, "Search Results for " + Chr(39) + keyword + Chr(39), xml.link, invalid, invalid)
                    'm.DisplayVideoListFromVideoList(videos, "Search Results for " + Chr(39) + keyword + Chr(39), invalid, invalid, invalid)
                m.FetchVideoList( "DoSearch", "Search Results for " + Chr(39) + keyword + Chr(39), false, {contentArg: parms}, "Please Wait..." )
                'else
                '    dialog.Close()
                '    ShowErrorDialog("No videos match your search", "Search results")
                'end if
            else if (msg.isCleared()) then
                history.Clear()
            else if ((msg.isRemoteKeyPressed() AND msg.GetIndex() = 10) OR msg.isButtonInfo()) then
                while (SearchOptionDialog() = 1)
                end while
            'else
                'print("Unhandled event on search screen")
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
End Sub

Function DoSearch_impl( searchParms as Object, pageToken = invalid as Dynamic ) as Dynamic
    parms = []
    for each parm in searchParms
        parms.push( { name: parm, value: searchParms[parm] } )
    end for
    parms.push( { name: "part", value: "id" } )
    parms.push( { name: "type", value: "video" } )
    parms.push( { name: "maxResults", value: "49" } )
    parms.push( { name: "fields", value: "items(id(videoId)),nextPageToken" } )
    if ( pageToken <> invalid ) then
        parms.push( { name: "pageToken", value: pageToken } )
    end if
    ' Get activity
    resp = m.BuildV3Request("search", parms)
    if ( resp <> invalid ) then
        vids = []
        for each item in resp.items
            'if ( item.snippet.type = "upload" ) then
            if ( item.id <> invalid AND item.id.videoId <> invalid ) then
                vids.Push( item.id.videoId )
            end if
        end for
        if ( vids.Count() > 0 ) then
            retVal = m.ExecBatchQueryV3( vids )
            retVal.nextPageToken = resp.nextPageToken
            return retVal
        end if
    end if
    return invalid
End Function

Function FindRelated_impl( relatedTo as String, pageToken = invalid as Dynamic ) as Dynamic
    parms = []
    parms.push( { name: "part", value: "id" } )
    parms.push( { name: "type", value: "video" } )
    parms.push( { name: "maxResults", value: "49" } )
    parms.push( { name: "fields", value: "items(id(videoId)),nextPageToken" } )
    parms.push( { name: "relatedToVideoId", value: relatedTo } )
    if ( pageToken <> invalid ) then
        parms.push( { name: "pageToken", value: pageToken } )
    end if
    ' Get activity
    resp = m.BuildV3Request("search", parms)
    if ( resp <> invalid ) then
        vids = []
        for each item in resp.items
            'if ( item.snippet.type = "upload" ) then
            if ( item.id <> invalid AND item.id.videoId <> invalid ) then
                vids.Push( item.id.videoId )
            end if
        end for
        if ( vids.Count() > 0 ) then
            retVal = m.ExecBatchQueryV3( vids )
            retVal.nextPageToken = resp.nextPageToken
            return retVal
        end if
    end if
    return invalid
End Function

Function GenerateSearchSuggestions(partSearchText As String) As Object
    suggestions = CreateObject("roArray", 1, true)
    length = len(partSearchText)
    if (length > 0) then
        searchRequest = CreateObject("roUrlTransfer")
        searchRequest.SetURL("http://suggestqueries.google.com/complete/search?hl=en&client=youtube&hjson=t&ds=yt&jsonp=window.yt.www.suggest.handleResponse&q=" + URLEncode(partSearchText))
        jsonAsString = searchRequest.GetToString()
        jsonAsString = strReplace(jsonAsString,"window.yt.www.suggest.handleResponse(","")
        jsonAsString = Left(jsonAsString, Len(jsonAsString) -1)
        response = simpleJSONParser(jsonAsString)
        aposRegex = CreateObject( "roRegex", "\\u0027", "ig" )

        if (islist(response) = true) then
            if (response.Count() > 1) then
                for each sugg in response[1]
                    suggestions.Push( aposRegex.replaceAll( sugg[0], "'" ) )
                end for
            end if
        end if

    else
        history = CreateObject("roSearchHistory")
        suggestions = history.GetAsArray()
    end if
    return suggestions
End Function

Function SearchOptionDialog() as Integer
    dialog = CreateObject("roMessageDialog")
    port = CreateObject("roMessagePort")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Search Settings")
    updateSearchDialogText(dialog)
    dialog.EnableBackButton(true)
    dialog.SetMenuTopLeft( true )
    dialog.addButton(1, "Change Length Filter")
    dialog.addButton(2, "Change Sort Setting")
    dialog.addButton(3, "Done")
    dialog.Show()
    while true
        dlgMsg = wait(2000, dialog.GetMessagePort())
        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isButtonPressed()) then
                if (dlgMsg.GetIndex() = 1) then
                    dialog.Close()
                    ret = SearchFilterClicked()
                    if (ret <> "ignore") then
                        m.youtube.searchLengthFilter = ret
                        if (ret <> "") then
                            RegWrite("length", ret, "Search")
                        else
                            RegDelete("length", "Search")
                        end if
                        updateSearchDialogText(dialog, true)
                    end if
                    return 1 ' Re-open the options
                else if (dlgMsg.GetIndex() = 2) then
                    dialog.Close()
                    ret = SearchSortClicked()
                    if (ret <> "ignore") then
                        m.youtube.searchSort = ret
                        if (ret <> "") then
                            RegWrite("sort", ret, "Search")
                        else
                            RegDelete("sort", "Search")
                        end if
                        updateSearchDialogText(dialog, true)
                    end if
                    return 1 ' Re-open the options
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
    ' print ("Exiting search option dialog")
    return 0
End Function

Sub updateSearchDialogText(dialog as Object, isUpdate = false as Boolean)
    searchLengthText = "None"
    searchSortText = "None"
    if (m.youtube.searchLengthFilter <> "") then
        searchLengthText = m.youtube.searchLengthFilter
    end if
    if (m.youtube.searchSort <> "") then
        searchSortText = GetSortText(m.youtube.searchSort)
    end if
    dialogText = "Length: " + searchLengthText + chr(10) + "Sort: " + searchSortText
    if (isUpdate = true) then
        dialog.UpdateText(dialogText)
    else
        dialog.SetText(dialogText)
    end if
End Sub

Function SearchFilterClicked() as String
    dialog = CreateObject("roMessageDialog")
    port = CreateObject("roMessagePort")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Length Filter")
    dialog.EnableBackButton(true)
    dialog.SetMenuTopLeft( true )
    dialog.addButton(1, "None")
    dialog.addButton(2, "Short (<4 minutes)")
    dialog.addButton(3, "Medium (>=4 and <=20 minutes)")
    dialog.addButton(4, "Long (>20 minutes)")
    if (m.youtube.searchLengthFilter = "Short") then
        dialog.SetFocusedMenuItem(1)
    else if (m.youtube.searchLengthFilter = "Medium") then
        dialog.SetFocusedMenuItem(2)
    else if (m.youtube.searchLengthFilter = "Long") then
        dialog.SetFocusedMenuItem(3)
    end if
    dialog.Show()
    retVal = "ignore"
    while true
        dlgMsg = wait(2000, dialog.GetMessagePort())
        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isButtonPressed()) then
                if (dlgMsg.GetIndex() = 1) then
                    retVal = ""
                else if (dlgMsg.GetIndex() = 2) then
                    retVal = "Short"
                else if (dlgMsg.GetIndex() = 3) then
                    retVal = "Medium"
                else if (dlgMsg.GetIndex() = 4) then
                    retVal = "Long"
                end if
                exit while
            else if (dlgMsg.isScreenClosed()) then
                exit while
            end if
        else if (dlgMsg = invalid) then
            CheckForMCast()
        end if
    end while
    dialog.Close()
    return retVal
End Function

Function SearchSortClicked() as String
    dialog = CreateObject("roMessageDialog")
    port = CreateObject("roMessagePort")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Sort Options")
    dialog.EnableBackButton(true)
    dialog.SetMenuTopLeft( true )
    dialog.addButton(1, "None")
    dialog.addButton(2, "Newest First")
    dialog.addButton(3, "Views (most to least)")
    dialog.addButton(4, "Rating (highest to lowest)")
    dialog.addButton(5, "Relevance (default)")
    dialog.addButton(6, "Title")
    if (m.youtube.searchSort = "date") then
        dialog.SetFocusedMenuItem(1)
    else if (m.youtube.searchSort = "viewCount") then
        dialog.SetFocusedMenuItem(2)
    else if (m.youtube.searchSort = "rating") then
        dialog.SetFocusedMenuItem(3)
    else if (m.youtube.searchSort = "relevance") then
        dialog.SetFocusedMenuItem(4)
    else if (m.youtube.searchSort = "title") then
        dialog.SetFocusedMenuItem(5)
    end if
    dialog.Show()
    retVal = "ignore"
    while true
        dlgMsg = wait(2000, dialog.GetMessagePort())
        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isButtonPressed()) then
                if (dlgMsg.GetIndex() = 1) then
                    retVal = ""
                else if (dlgMsg.GetIndex() = 2) then
                    retVal = "date"
                else if (dlgMsg.GetIndex() = 3) then
                    retVal = "viewCount"
                else if (dlgMsg.GetIndex() = 4) then
                    retVal = "rating"
                else if (dlgMsg.GetIndex() = 5) then
                    retVal = "relevance"
                else if (dlgMsg.GetIndex() = 6) then
                    retVal = "title"
                end if
                exit while
            else if (dlgMsg.isScreenClosed()) then
                exit while
            end if
        else if (dlgMsg = invalid) then
            CheckForMCast()
        end if
    end while
    dialog.Close()
    return retVal
End Function

Function GetSortText(internalValue as String) as String
    retVal = "None"
    if (m.youtube.searchSort = "date") then
        retVal = "Newest First"
    else if (m.youtube.searchSort = "viewCount") then
        retVal = "Views"
    else if (m.youtube.searchSort = "rating") then
        retVal = "Rating"
    else if (m.youtube.searchSort = "relevance") then
        retVal = "Relevance"
    else if (m.youtube.searchSort = "title") then
        retVal = "Title"
    end if
    return retVal
End Function