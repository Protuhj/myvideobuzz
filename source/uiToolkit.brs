
'  uitkDoPosterMenu
'
'    Display "menu" items in a Poster Screen.
'
Library "v30/bslCore.brs"
Function uitkPreShowPosterMenu( ListStyle="flat-category" as String, breadA = "Home", breadB = invalid ) As Object
    port = CreateObject( "roMessagePort" )
    screen = CreateObject( "roPosterScreen" )
    screen.SetMessagePort(port)

    if (breadA <> invalid and breadB <> invalid) then
        screen.SetBreadcrumbText(breadA, breadB)
    else if (breadA <> invalid and breadB = invalid) then
        screen.SetBreadcrumbText(breadA, "")
        screen.SetTitle(breadA)
    end if

    if (ListStyle = "" OR ListStyle = invalid) then
        ListStyle = "flat-category"
    end if

    screen.SetListStyle(ListStyle)
    screen.SetListDisplayMode("scale-to-fit")
    ' screen.SetListDisplayMode("zoom-to-fill")
    screen.Show()

    return screen
end function

Function uitkDoPosterMenu( posterdata, screen, onselect_callback = invalid, onplay_func = invalid ) As Integer
    if (type(screen) <> "roPosterScreen") then
        'print "illegal type/value for screen passed to uitkDoPosterMenu()"
        return -1
    end if

    screen.SetContentList(posterdata)
    idx% = 0

    ' If the first item is a button, and the 2nd item isn't a button, select the 2nd item.
    if ( posterdata[0]["action"] <> invalid AND posterdata.Count() > 1 AND posterdata[1]["action"] = invalid ) then
        idx% = 1
        screen.SetFocusedListItem( idx% )
    end if

    while (true)
        msg = wait(2000, screen.GetMessagePort())

        'print "uitkDoPosterMenu | msg type = ";type(msg)
        if (type(msg) = "roPosterScreenEvent") then
            'print "event.GetType()=";msg.GetType(); " event.GetMessage()= "; msg.GetMessage()
            if (msg.isListItemSelected()) then
                if (onselect_callback <> invalid) then
                    selecttype = onselect_callback[0]
                    if (selecttype = 0) then
                        this = onselect_callback[1]
                        selected_callback = onselect_callback[msg.GetIndex() + 2]
                        if (islist(selected_callback)) then
                            f = selected_callback[0]
                            userdata1 = selected_callback[1]
                            userdata2 = selected_callback[2]
                            userdata3 = selected_callback[3]

                            if (userdata1 = invalid) then
                                this[f]()
                            else if (userdata2 = invalid) then
                                this[f](userdata1)
                            else if (userdata3 = invalid) then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if (selected_callback = "return") then
                                return msg.GetIndex()
                            else if (selected_callback = "AddAccount") then
                                if (this[selected_callback]() = true) then
                                    screen.close()
                                    ShowHomeScreen()
                                    ' Return value seems to be unused
                                    return 0
                                end if
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if (selecttype = 1) then
                        userdata1 = onselect_callback[1]
                        userdata2 = onselect_callback[2]
                        f = onselect_callback[3]
                        idx% = f(userdata1, userdata2, msg.GetIndex())
                        screen.SetFocusedListItem( idx% )
                    end if
                else
                    return msg.GetIndex()
                end if
            else if (msg.isScreenClosed()) then
                return -1
            else if (msg.isListItemFocused()) then
                idx% = msg.GetIndex()
            else if (msg.isRemoteKeyPressed()) then
                ' If the play button is pressed on the video list, and the onplay_func is valid, play the video
                if (onplay_func <> invalid ) then
                    if ( msg.GetIndex() = bslUniversalControlEventCodes().BUTTON_PLAY_PRESSED ) then
                        onplay_func( posterdata[idx%] )
                    else if ( msg.GetIndex() = bslUniversalControlEventCodes().BUTTON_INFO_PRESSED ) then
                        while ( VListOptionDialog( posterdata[idx%] ) = 1 )
                        end while
                    end if
                end if
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
End Function


Sub uitkPreShowListMenu( context, content as Object, headerText as String, breadA = invalid, breadB = invalid )
    port = CreateObject( "roMessagePort" )
    screen = CreateObject( "roListScreen" )
    screen.SetMessagePort( port )
    screen.SetHeader( headerText )
    screen.SetupBehaviorAtTopRow( "exit" )

    if ( breadA <> invalid and breadB <> invalid ) then
        ' Wrap this call in an eval to catch any potential firmware support issue
        ret = eval( "screen.SetBreadcrumbText( breadA, breadB )" )
        if ( ret <> m.constants.ERR_NORMAL_END AND ret <> m.constants.ERR_VALUE_RETURN ) then
            screen.SetTitle( breadA )
        end if
    else if ( breadA <> invalid and breadB = invalid ) then
        ' Wrap this call in an eval to catch any potential firmware support issue
        ret = eval( "screen.SetBreadcrumbText( breadA, " + Quote() + Quote() + " )" )
        if ( ret <> m.constants.ERR_NORMAL_END AND ret <> m.constants.ERR_VALUE_RETURN ) then
            screen.SetTitle( breadA )
        end if
    end if
    prefs = getPrefs()
    screen.Show()
    screen.SetContent( content )
    while (true)
        msg = wait(2000, screen.GetMessagePort())

        'print "uitkDoPosterMenu | msg type = ";type(msg)
        if (type(msg) = "roListScreenEvent") then
            if ( msg.isListItemSelected() ) then
                index% = msg.GetIndex()
                prefData = content[ index% ].prefData
                if ( content[ index% ].callback <> invalid ) then
                    context[ content[ index% ].callback ]()
                else if ( prefData <> invalid ) then
                    newBreadA = breadB
                    if ( newBreadA = invalid ) then
                        newBreadA = headerText
                    end if
                    ' Handle enum preference
                    newData = {}
                    newData.Append( content[ index% ] )
                    newData.Append( prefData )
                    newData.Delete( "prefData" )
                    if ( prefData.type <> "string" ) then
                        result = uitkEnumOptionScreen( newData, newBreadA, prefData.name )
                    else
                        result = getKeyboardInput( "Enter the " + prefData.name, prefData.desc, prefData.value, "Save" )
                    end if
                    if ( result <> invalid AND prefData.value <> result ) then
                        print "Preference value changed, was: " ; tostr( prefData.value ); " is now: " ; tostr( result )
                        prefs.setPrefValue( prefData.key, result )
                        prefData.value = result
                    end if
                end if
            else if (msg.isScreenClosed()) then
                exit while
            else if (msg.isListItemFocused()) then
                idx% = msg.GetIndex()
            end if
        else if ( msg = invalid ) then
            CheckForMCast()
        end if
    end while

End Sub

Function uitkEnumOptionScreen( prefData as Object, breadA = invalid, breadB = invalid ) as Integer
    port = CreateObject( "roMessagePort" )
    screen = CreateObject( "roListScreen" )
    screen.SetMessagePort( port )
    screen.SetHeader( prefData.desc )
    screen.SetupBehaviorAtTopRow( "exit" )

    if ( breadA <> invalid and breadB <> invalid ) then
        ' Wrap this call in an eval to catch any potential firmware support issue
        ret = eval( "screen.SetBreadcrumbText( breadA, breadB )" )
        if ( ret <> m.constants.ERR_NORMAL_END AND ret <> m.constants.ERR_VALUE_RETURN ) then
            screen.SetTitle( breadA )
        end if
    else if ( breadA <> invalid and breadB = invalid ) then
        ' Wrap this call in an eval to catch any potential firmware support issue
        ret = eval( "screen.SetBreadcrumbText( breadA, " + Quote() + Quote() + " )" )
        if ( ret <> m.constants.ERR_NORMAL_END AND ret <> m.constants.ERR_VALUE_RETURN ) then
            screen.SetTitle( breadA )
        end if
    end if
    if ( isint( prefData.value ) ) then
        focusedIndex% = prefData.value
    else
        focusedIndex% = 0
    end if
    returnIndex% = focusedIndex%

    for each option in prefData.values
        metadata = {
            title: option,
            HDPosterUrl: prefData.HDPosterUrl,
            SDPosterUrl: prefData.SDPosterUrl
        }
        screen.AddContent( metadata )
    next

    screen.SetFocusedListItem( focusedIndex% )
    screen.Show()
    while (true)
        msg = wait(2000, screen.GetMessagePort())

        if (type(msg) = "roListScreenEvent") then
            if ( msg.isListItemSelected() ) then
                returnIndex% = msg.GetIndex()
                exit while
            else if (msg.isScreenClosed()) then
                exit while
            end if
        else if ( msg = invalid ) then
            CheckForMCast()
        end if
    end while
    return returnIndex%
End Function

Function determinePageEnd( start% as Integer, text as String ) as Integer
    maxLines% = 9
    lines% = 0
    curPos% = start%
    textLen% = len( text )
    while ( curPos% < textLen% AND lines% <= maxLines% )
        ' Find the first instance of a newline character
        nextPos% = instr( curPos%, text, Chr(10) )
        ' If the newline was found
        if ( nextPos% <> 0 ) then
            diff% = nextPos% - curPos%
            ' max 80 chars per line
            preLines% = lines%
            lines% = lines% + ( diff% / 80 ) + 1
            ' print( tostr( diff% ) + "] Next line(s): [" + tostr( lines% ) + "] " + Mid( text, curPos%, diff% ) )

            if ( lines% < maxLines% ) then
                ' If we're under the max # of lines, move the current position past the last found newline
                curPos% = nextPos% + 1
            else if ( lines% = maxLines% ) then
                ' If we're at the max # of lines, just return the current position of the newline
                curPos% = nextPos%
            else
                ' If we're over the max # of lines, determine the position that will fit on the screen.
                diffLines% = maxLines% - preLines%
                'print("diffLines: " + tostr(diffLines%) + " curpos: " + tostr(curPos%))
                curPos% = curPos% + ( 80 * diffLines% )
            end if
        else if ( (textLen% - curPos%) > (80 * maxLines%) ) then
            lines% = maxLines%
            curPos% = curPos% + (80 * maxLines%)
            exit while
        else
            exit while
        end if
    end while
    if ( lines% = 0 ) then
        return 0
    else
        if ( curPos% > textLen% ) then
            return textLen%
        else
            return curPos%
        end if
    end if
End Function

Sub uitkTextScreen( title as String, headerText as String, text as String, showTitleText as Boolean )
    regexNL = CreateObject( "roRegex", "\n{3,}", "ig" )
    regexCR = CreateObject( "roRegex", "\r", "ig" )
    port = CreateObject( "roMessagePort" )
    text = regexNL.ReplaceAll( text, Chr(10) + Chr(10) )
    text = regexCR.ReplaceAll( text, "" )

    continueLoop = true
    curPage% = 0
    pageData = []
    start% = 1
    res% = determinePageEnd( start%, text )
    while ( res% <> 0 )
        pageData.push( {p: start%, n: res% - start% } )
        ' print("Pushing: p: " + tostr( start% ) + " n: " + tostr(res% - start%) )
        start% = res% + 1
        res% = determinePageEnd( start%, text )
    end while
    maxPages% = pageData.Count()
    prevScreen = invalid
    while ( continueLoop )
        screen = CreateObject( "roParagraphScreen" )
        screen.SetMessagePort( port )
        screen.SetTitle( title )
        if (showTitleText) then
            screen.AddParagraph( "Title: " + headerText )
        else
            screen.AddParagraph( headerText )
        end if

        if ( maxPages% > 1 ) then
            if ( curPage% = (maxPages% - 1) ) then
                screen.AddParagraph( Mid( text, pageData[curPage%].p ) )
            else
                screen.AddParagraph( Mid( text, pageData[curPage%].p, pageData[curPage%].n ) )
            end if

            if ( curPage% <> (maxPages% - 1) ) then
                screen.AddButton( 0, "More" )
            end if
            if ( curPage% > 0 ) then
                screen.AddButton( 1, "Previous" )
            end if
        else
            maxPages% = 1
            screen.AddParagraph( text )
        end if
        screen.AddButton( 2, "Close (" + tostr( curPage% + 1 ) + "/" + tostr( maxPages% ) + ")" )
        screen.Show()
        if ( prevScreen <> invalid ) then
            prevScreen.close()
            prevScreen = invalid
        end if
        blockClosing = false
        while ( true )
            msg = wait( 2000, port )
            if ( type( msg ) = "roParagraphScreenEvent" ) then
                if ( msg.isScreenClosed() ) then
                    if ( NOT( blockClosing) ) then
                        continueLoop = false
                    end if
                    exit while
                else if ( msg.isButtonPressed() ) then
                    btnIndex% = msg.GetIndex()
                    blockClosing = true

                    if ( btnIndex% = 0 ) then
                        ' More button
                        curPage% = curPage% + 1
                    else if ( btnIndex% = 1 ) then
                        ' Previous button
                        curPage% = curPage% - 1
                    else if ( btnIndex% = 2 ) then
                        ' Close button
                        curPage% = curPage% + 1
                        blockClosing = false
                    end if
                    if ( NOT( blockClosing ) ) then
                        screen.close()
                    else
                        prevScreen = screen
                        exit while
                    end if
                end if
            else if ( msg = invalid ) then
                CheckForMCast()
            end if
        end while
    end while
End Sub


Function uitkDoListMenu(posterdata, screen, onselect_callback=invalid) As Integer

    if (type(screen) <> "roListScreen") then
        'print "illegal type/value for screen passed to uitkDoListMenu()"
        return -1
    end if

    screen.SetContent(posterdata)

    while (true)
        msg = wait(2000, screen.GetMessagePort())

        if (type(msg) = "roListScreenEvent") then
            'print "event.GetType()=";msg.GetType(); " Event.GetMessage()= "; msg.GetMessage()
            if (msg.isListItemSelected()) then
                if (onselect_callback <> invalid) then
                    selecttype = onselect_callback[0]
                    if (selecttype = 0) then
                        this = onselect_callback[1]
                        selected_callback = onselect_callback[msg.GetIndex() + 2]
                        if (islist(selected_callback)) then
                            f = selected_callback[0]
                            userdata1 = selected_callback[1]
                            userdata2 = selected_callback[2]
                            userdata3 = selected_callback[3]

                            if (userdata1 = invalid) then
                                this[f]()
                            else if (userdata2 = invalid) then
                                this[f](userdata1)
                            else if (userdata3 = invalid) then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if (selected_callback = "return") then
                                return msg.GetIndex()
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if (selecttype = 1) then
                        userdata1=onselect_callback[1]
                        userdata2=onselect_callback[2]
                        f=onselect_callback[3]
                        f(userdata1, userdata2, msg.GetIndex())
                    end if
                else
                    return msg.GetIndex()
                end if
            else if (msg.isScreenClosed()) then
                return -1
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
    return 0
End Function


Function uitkDoCategoryMenu(categoryList, screen, content_callback = invalid, onclick_callback = invalid, onplay_func = invalid, isPlaylist = false as Boolean, isReddit = false as Boolean) As Integer
    'Set current category to first in list
    category_idx = 0
    category_queried = 0
    contentlist = []
    screen.SetListNames( categoryList )
    contentdata1 = content_callback[0]
    contentdata2 = content_callback[1]
    content_f = content_callback[2]

    ' If the content function returns invalid data, don't crash the channel.
    contentlist = firstValid( content_f( contentdata1, contentdata2, 0 ), [] )

    if ( contentlist.Count() = 0 ) then
        screen.SetContentList( [] )
        screen.ClearMessage()
        screen.ShowMessage( "No viewable content in this section" )
    else
        screen.SetContentList( contentlist )
        screen.ClearMessage()
    end if
    screen.Show()

    idx% = 0
    contentdata1 = invalid
    contentdata2 = invalid
    content_f = invalid
    ' Tracks when the category was selected
    category_time = CreateObject("roTimespan")
    ' Tracks the amount of time between CheckForMCast calls
    multicast_time = CreateObject("roTimespan")
    ' This flag is used to determine when a query to the server for category data
    ' should actually occur, rather than every time a category was selected
    awaiting_timeout = false
    ' Default the multicast timer
    multicast_time.Mark()
    buttonCodes = bslUniversalControlEventCodes()
    while (true)
        msg = wait(500, screen.GetMessagePort())
        if (type(msg) = "roPosterScreenEvent") then
            if (msg.isListFocused()) then
                ' This event occurs when the category header is selected
                category_idx = msg.GetIndex()
                contentdata1 = content_callback[0]
                contentdata2 = content_callback[1]
                content_f = content_callback[2]

                ' Determine if the category that has been focused is the "Load More" item, that allows loading more than 50 playlists/subscriptions
                if ( contentdata1[category_idx]["action"] <> invalid ) then
                    contentlist = [ contentdata1[ category_idx ] ]
                    screen.SetContentList( contentlist )
                    idx% = 0
                    awaiting_timeout = false
                else
                    ' Track that a timeout is being awaited
                    awaiting_timeout = true
                    ' Mark the time that the category was selected
                    category_time.Mark()
                end if
            else if (msg.isListItemSelected()) then
                if ( contentlist[idx%]["action"] <> invalid AND contentlist[idx%]["isMoreLink"] <> invalid ) then
                    ' Handle the item that loads more playlists/subscriptions
                    contentlist[idx%]["depth"] = firstValid( contentlist[idx%]["depth"], 1 ) + 1
                    m.youtube.FetchVideoList( contentlist[idx%].contentFunc, firstValid( contentlist[idx%]["origTitle"], contentlist[idx%]["screenTitle"], "Items" ) + " Page " + tostr( contentlist[idx%]["depth"] ), true, {nextPageToken: contentlist[idx%].nextPageToken, itemFunc: contentlist[idx%].itemFunc, contentArg: contentlist[idx%].contentArg, isPlaylist: isPlaylist, origTitle: firstValid( contentlist[idx%]["origTitle"], contentlist[idx%]["screenTitle"] ), depth: contentlist[idx%]["depth"]}, "Loading more items..." )
                    contentlist[idx%]["depth"] = contentlist[idx%]["depth"] - 1 
                else
                    ' This event occurs when a video is selected with the "Ok" button
                    userdata1 = onclick_callback[0]
                    userdata2 = onclick_callback[1]
                    content_f = onclick_callback[2]

                    ' Reset the awaiting_timeout flag if an item is clicked
                    awaiting_timeout = false
                    category_time.Mark()

                    contentData = content_f(userdata1, userdata2, contentlist, category_idx, msg.GetIndex())
                    if ( contentData <> invalid ) then
                        ' Handles when the Back/Forward arrows are clicked
                        if ( contentData.isContentList = true ) then
                            contentlist = contentData.content
                            if (contentlist.Count() <> 0) then
                                if ( contentlist[0]["action"] <> invalid AND contentlist.Count() > 1 ) then
                                    screen.SetFocusedListItem(1)
                                else
                                    screen.SetFocusedListItem(0)
                                end if
                                screen.SetContentList(contentlist)
                                screen.Show()
                                'screen.SetFocusedListItem(msg.GetIndex())
                            end if
                        else if ( contentData.vidIdx <> invalid ) then
                            ' If the user has changed the video selection, either via Play All
                            ' or via the left/right buttons, change the selected video to match what they
                            ' had selected on the details screen.
                            screen.SetFocusedListItem( contentData.vidIdx )
                        end if
                    else
                        print "uitkDoCategoryMenu content function returned invalid content data!"
                    end if
                end if
            else if (msg.isListItemFocused()) then
                ' This event occurs when the user changes the selection of a video item
                idx% = msg.GetIndex()
            else if (msg.isScreenClosed()) then
                return -1
            else if (msg.isRemoteKeyPressed()) then
                ' If the play button is pressed on the video list, and the onplay_func is valid, play the video
                if (onplay_func <> invalid AND msg.GetIndex() = buttonCodes.BUTTON_PLAY_PRESSED AND contentlist[idx%]["isPlaylist"] <> true) then
                    ' Stops the annoyance when a video finishes playing and the banner gets re-selected.
                    screen.SetFocusToFilterBanner( false )
                    onplay_func(contentlist[idx%])
                ' If the * button is pressed while viewing a playlist, show the option to reverse it.
                else if ( awaiting_timeout = false AND isPlaylist = true AND msg.GetIndex() = buttonCodes.BUTTON_INFO_PRESSED ) then
                    while ( VListOptionDialog( contentlist[idx%] ) = 1 )
                    end while
                else if ( awaiting_timeout = false AND isPlaylist = false AND msg.GetIndex() = buttonCodes.BUTTON_INFO_PRESSED ) then
                    redditFeedType = m.prefs.getPrefValue( m.prefs.RedditFeed.key )
                    redditFilterType = m.prefs.getPrefValue( m.prefs.RedditFilter.key )
                    while ( VListOptionDialog( contentlist[idx%], isReddit ) = 1 )
                    end while
                    redditFeedTypeAfter = m.prefs.getPrefValue( m.prefs.RedditFeed.key )
                    redditFilterTypeAfter = m.prefs.getPrefValue( m.prefs.RedditFilter.key )
                    if ( redditFeedType <> redditFeedTypeAfter OR redditFilterType <> redditFilterTypeAfter ) then
                        redditQueryTypeText = firstValid( getEnumValueForType( getConstants().eREDDIT_QUERIES, redditFeedTypeAfter ), "Hot" )
                        redditFilterTypeText = firstValid( getEnumValueForType( getConstants().eREDDIT_FILTERS, redditFilterTypeAfter ), "All" )
                        contentlist = content_callback[2]( content_callback[0], content_callback[1], category_idx )
                        title = "Reddit (" + redditQueryTypeText
                        if ( redditQueryTypeText = "Top" or redditQueryTypeText = "Controversial" ) then
                            title = title + " - " + redditFilterTypeText + ")"
                        else
                            title = title + ")"
                        end if
                        screen.SetBreadcrumbText( title, "" )
                        screen.SetTitle( title )
                        if ( contentlist.Count() = 0 ) then
                            screen.SetContentList( [] )
                            screen.ClearMessage()
                            screen.ShowMessage( "No viewable content in this section" )
                        else
                            screen.SetContentList( contentlist )
                            screen.ClearMessage()
                            screen.SetFocusedListItem( 0 )
                            screen.Show()
                        end if
                    end if
                end if
            end if
        else if (msg = invalid) then
            ' This addresses the issue when trying to scroll quickly through the category list,
            ' previously, each category would queue a request to YouTube, and the user would have to wait when they
            ' reached their desired category for the correct video list to load (could be painful with a lot of categories)
            if ( awaiting_timeout = true AND category_time.TotalMilliseconds() > 1000 ) then
                awaiting_timeout = false
                if ( category_queried <> category_idx ) then
                    category_queried = category_idx
                    ' This calls the content callback
                    ' If the content function returns invalid data, don't crash the channel.
                    contentlist = firstValid( content_f( contentdata1, contentdata2, category_idx ), [] )
                    if (contentlist.Count() = 0) then
                        screen.SetContentList([])
                        screen.ShowMessage("No viewable content in this section")
                    else
                        screen.SetContentList(contentlist)
                        screen.SetFocusedListItem(0)
                        idx% = 0
                    end if
                else
                    print ("Not querying same item.")
                end if
            else if (multicast_time.TotalSeconds() > 2) then
                ' Don't allow the CheckForMCast function to run too much due to the category query change
                multicast_time.Mark()
                CheckForMCast()
            end if
        end If
    end while
End Function

Sub uitkDoMessage(message, screen)
    screen.showMessage(message)
    while (true)
        msg = wait(0, screen.GetMessagePort())
        if (msg.isScreenClosed()) then
            return
        end if
    end while
End Sub

Function VListOptionDialog( videoObj as Object, isReddit = false as Boolean ) as Integer
    dialog = CreateObject( "roMessageDialog" )
    port = CreateObject( "roMessagePort" )
    dialog.SetMessagePort( port )
    dialog.SetTitle( "Playback Settings" )
    dialog.SetMenuTopLeft( true )
    updateVListDialogText( dialog, false, isReddit )
    dialog.EnableBackButton( true )
    redditFilterId = 0
    redditFeedId   = 0
    sleepId = 1
    doneId = 2
    detailsId = 3
    playlistId = 4
    audioOnlyId = 5
    dialog.addButton( sleepId, "Set Sleep Timer" )
    audioButtonTextBase = "Play Audio Only? (If possible): "
    audioButtonText = audioButtonTextBase
    if ( m.youtube.audio_only ) then
        audioButtonText = audioButtonText + " Yes"
    else
        audioButtonText = audioButtonText + " No"
    end if
    dialog.addButton( audioOnlyId, audioButtonText )
    if ( videoObj <> invalid AND videoObj["Description"] <> invalid AND len( videoObj["Description"] ) > 0 ) then
        dialog.addButton( detailsId, "View Full Description" )
    end if
    if ( videoObj <> invalid AND firstValid( videoObj[ "HasPlaylist" ], false ) = true ) then
        dialog.addButton( playlistId, "View Playlist" )
    end if
    if ( isReddit = true ) then
        redditFeedId = 8
        redditFilterId = 9
        dialog.addButton( redditFeedId, "Reddit Feed" )
        dialog.addButton( redditFilterId, "Reddit Filter" )
    end if
    dialog.addButton( doneId, "Done" )
    dialog.Show()
    while true
        dlgMsg = wait(2000, dialog.GetMessagePort())
        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isButtonPressed()) then
                buttonPressed = dlgMsg.GetIndex()
                ' This will be for the sleep timer menu
                if ( buttonPressed = sleepId ) then
                    dialog.Close()
                    ret = SleepTimerClicked()
                    if (ret <> 0) then
                        m.youtube.sleep_timer = ret
                        updateVListDialogText( dialog, true, isReddit )
                    end if
                    return 1 ' Re-open the options
                else if ( buttonPressed = detailsId ) then
                    dialog.Close()
                    descr = videoObj["Description"]
                    if ( videoObj["FullDescription"] <> invalid ) then
                        descr = videoObj["FullDescription"]
                    end if
                    uitkTextScreen( "Full Description", videoObj["TitleSeason"], descr, true )
                    return 0
                else if ( buttonPressed = playlistId ) then ' View Playlist
                    plId = firstValid( videoObj[ "PlaylistID" ], invalid )
                    if ( plId <> invalid ) then
                        dialog.Close()
                        m.youtube.FetchVideoList( "GetPlaylistItems", videoObj[ "TitleSeason" ], false, {contentArg: plId}, "Loading playlist...", true )
                    else
                        print "Couldn't find playlist id for URL: " ; videoObj["URL"]
                    end if
                    return 0
                else if ( buttonPressed = redditFeedId ) then ' Reddit Feed
                    dialog.Close()
                    curSelection = m.prefs.getPrefValue( m.constants.pREDDIT_FEED )
                    ret = RedditPrefClicked( m.prefs.RedditFeed.values, curSelection, "Reddit Feed Settings" )
                    if ( ret <> -1 ) then
                        m.prefs.setPrefvalue( m.constants.pREDDIT_FEED, ret )
                        updateVListDialogText( dialog, true, isReddit )
                    end if
                    return 1 ' Re-open the options
                else if ( buttonPressed = redditFilterId ) then ' Reddit Filter
                    dialog.Close()
                    curSelection = m.prefs.getPrefValue( m.constants.pREDDIT_FILTER)
                    ret = RedditPrefClicked( m.prefs.RedditFilter.values, curSelection, "Reddit Filter Settings" )
                    if ( ret <> -1 ) then
                        m.prefs.setPrefvalue( m.constants.pREDDIT_FILTER, ret )
                        updateVListDialogText( dialog, true, isReddit )
                    end if
                    return 1 ' Re-open the options
                else if ( buttonPressed = audioOnlyId ) then ' Audio Only
                    m.youtube.audio_only = NOT(m.youtube.audio_only)
                    audioButtonText = audioButtonTextBase
                    if ( m.youtube.audio_only ) then
                        audioButtonText = audioButtonText + " Yes"
                    else
                        audioButtonText = audioButtonText + " No"
                    end if
                    dialog.UpdateButton( audioOnlyId, audioButtonText )
                else if ( buttonPressed = doneId ) then
                    dialog.Close()
                    exit while
                end if
            else if ( dlgMsg.isScreenClosed() ) then
                dialog.Close()
                exit while
            else
                ' print ("Unhandled msg type")
                exit while
            end if
        else if ( dlgMsg = invalid ) then
            CheckForMCast()
        else
            ' print ("Unhandled msg: " + type(dlgMsg))
            exit while
        end if
    end while
    return 0
End Function

Sub updateVListDialogText( dialog as Object, isUpdate as Boolean, isReddit as Boolean )
    sleepText = "Off"
    if ( m.youtube.sleep_timer <> -100 ) then
        sleepText = get_length_as_human_readable( m.youtube.sleep_timer )
    end if

    dialogText = "Sleep Timer: " + sleepText
    if ( isReddit = true ) then
        redditFeedType = firstValid( getEnumValueForType( getConstants().eREDDIT_QUERIES, m.prefs.getPrefValue( m.prefs.RedditFeed.key ) ), "Hot" )
        redditFilterType = firstValid( getEnumValueForType( getConstants().eREDDIT_FILTERS, m.prefs.getPrefValue( m.prefs.RedditFilter.key ) ), "All" )
        dialogText = dialogText + chr( 10 ) + "Reddit Feed: " + redditFeedType + chr( 10 )
        dialogText = dialogText + "Reddit Filter: " + redditFilterType
    end if
    if ( isUpdate = true ) then
        dialog.UpdateText( dialogText )
    else
        dialog.SetText( dialogText )
    end if
End Sub

Function SleepTimerClicked() as Integer
    dialog = CreateObject( "roMessageDialog" )
    port = CreateObject( "roMessagePort" )
    dialog.SetMessagePort( port )
    dialog.SetTitle( "Sleep Timer Settings" )
    dialog.SetMenuTopLeft( true )
    dialog.EnableBackButton( true )
    dialog.addButton( -1, "Off")
    dialog.addButton( 30, "30 minutes" )
    dialog.addButton( 45, "45 minutes" )
    dialog.addButton( 60, "60 minutes" )
    dialog.addButton( 75, "75 minutes" )
    dialog.addButton( 90, "90 minutes" )
    dialog.Show()
    retVal = 0
    while true
        dlgMsg = wait( 2000, dialog.GetMessagePort() )
        if ( type (dlgMsg ) = "roMessageDialogEvent" ) then
            if ( dlgMsg.isButtonPressed() ) then
                if ( dlgMsg.GetIndex() = -1 ) then
                    retVal = -100
                else
                    retVal = dlgMsg.GetIndex() * 60
                end if
                exit while
            else if ( dlgMsg.isScreenClosed() ) then
                exit while
            end if
        else if (dlgMsg = invalid) then
            CheckForMCast()
        end if
    end while
    dialog.Close()
    return retVal
End Function

Function RedditPrefClicked( values as Object, currentSelection as Integer, title as String ) as Integer
    dialog = CreateObject( "roMessageDialog" )
    port = CreateObject( "roMessagePort" )
    dialog.SetMessagePort( port )
    dialog.SetTitle( title )
    dialog.SetMenuTopLeft( true )
    dialog.EnableBackButton( true )
    idx% = 0
    for each item in values
        dialog.addButton( idx%, item )
        idx% = idx% + 1
    next
    dialog.SetFocusedMenuItem( currentSelection )
    dialog.Show()
    retVal = -1
    while true
        dlgMsg = wait( 2000, dialog.GetMessagePort() )
        if ( type (dlgMsg ) = "roMessageDialogEvent" ) then
            if ( dlgMsg.isButtonPressed() ) then
                retVal = dlgMsg.GetIndex()
                exit while
            else if ( dlgMsg.isScreenClosed() ) then
                exit while
            end if
        else if (dlgMsg = invalid) then
            CheckForMCast()
        end if
    end while
    dialog.Close()
    return retVal
End Function
