Function InitYouTube() As Object
    ' constructor
    this = CreateObject("roAssociativeArray")
    this.DEBUG = false
    this.userName = RegRead("YTUSERNAME1", invalid)
    this.channelId = RegRead("ytChannelId", invalid)
    this.funcmap = invalid
    this.JSUrl = ""
    this.STSVal = firstValid( RegRead("YT_STS_VAL", invalid), "17295" )
    this.home_screen = invalid
    this.link_prefix = "https://www.google.com/device"
    this.v3Base = "https://www.googleapis.com/youtube/v3/"
    this.device_id = CreateObject("roDeviceInfo").GetDeviceUniqueId()
    this.protocol = "http"
    this.scope = this.protocol + "://gdata.youtube.com"
    this.prefix = this.scope + "/feeds/api"
    this.currentURL = ""
    this.searchLengthFilter = ""
    this.stuff = buildIt( 13, 25, 8 )
    tmpLength = RegRead("length", "Search")
    if (tmpLength <> invalid) then
        this.searchLengthFilter = tmpLength
    end if
    ' Version of the searchLength value.
    this.searchLengthHistory = "2"
    searchLengthVer = RegRead( "SearchLengthVersion", "Settings" )
    if ( searchLengthVer = invalid OR searchLengthVer <> this.searchLengthHistory ) then
        print( "Search Length version mismatch (clearing setting), found: " + tostr( searchLengthVer ) + ", expected: " + this.searchLengthHistory )
        this.searchLengthFilter = ""
        RegDelete("length", "Search")
        RegWrite( "SearchLengthVersion", this.searchLengthHistory, "Settings" )
    end if

    this.searchSort = ""
    tmpSort = RegRead("sort", "Search")
    if (tmpSort <> invalid) then
        this.searchSort = tmpSort
    end if
    ' Version of the searchSort value.
    this.searchSortHistory = "2"
    searchSortVer = RegRead( "SearchSortVersion", "Settings" )
    if ( searchSortVer = invalid OR searchSortVer <> this.searchSortHistory ) then
        print( "Search Sort version mismatch (clearing setting), found: " + tostr( searchSortVer ) + ", expected: " + this.searchSortHistory )
        this.searchSort = ""
        RegDelete("sort", "Search")
        RegWrite( "SearchSortVersion", this.searchSortHistory, "Settings" )
    end if

    this.searchLive = ""
    tmpLive = RegRead("live", "Search")
    if (tmpLive <> invalid) then
        this.searchLive = tmpLive
    end if
    ' Version of the searchLive value.
    this.searchLiveHistory = "1"
    searchLiveVer = RegRead( "SearchLiveVersion", "Settings" )
    if ( searchLiveVer = invalid OR searchLiveVer <> this.searchLiveHistory ) then
        print( "Search Live version mismatch (clearing setting), found: " + tostr( searchLiveVer ) + ", expected: " + this.searchLiveHistory )
        this.searchLive = ""
        RegDelete("live", "Search")
        RegWrite( "SearchLiveVersion", this.searchLiveHistory, "Settings" )
    end if

    this.CurrentPageTitle = ""

    'API Calls
    this.ExecBatchQueryV3 = ExecBatchQueryV3_impl

    'Search
    this.SearchYouTube = SearchYouTube_impl

    'User videos
    this.BrowseUserVideos = BrowseUserVideos_impl
    this.GetActivity = GetActivity_impl
    this.GetFilteredActivity = GetFilteredActivity_impl

    ' Playlists
    this.BrowseUserPlaylists = BrowseUserPlaylists_impl

    'Videos
    this.DisplayVideoListFromVideoList = DisplayVideoListFromVideoList_impl
    this.DisplayVideoListFromMetadataList = DisplayVideoListFromMetadataList_impl
    this.FetchVideoList = FetchVideoList_impl

    this.VideoDetails = VideoDetails_impl
    this.newVideoListFromJSON = newVideoListFromJSON_impl
    this.newVideoFromJSON = newVideoFromJSON_impl
    this.ReturnVideoList = ReturnVideoList_impl

    this.BuildV3Request = BuildV3Request_impl
    ' v3 API Requests
    this.MySubscriptions = MySubscriptions_impl
    this.GetVideosActivity = GetVideosActivity_impl
    this.MyPlaylists = MyPlaylists_impl
    this.GetPlaylists = GetPlaylists_impl
    this.GetPlaylistItems = GetPlaylistItems_impl
    this.GetWhatsNew = GetWhatsNew_impl
    this.MostPopular = MostPopular_impl
    this.GetMostPopular = GetMostPopular_impl
    this.DoSearch = DoSearch_impl
    this.FindRelated = FindRelated_impl

    'Categories
    this.CategoriesListFromJSON  = CategoriesListFromJSON_impl

    'Settings
    this.BrowseSettings = youtube_browse_settings
    this.About = aboutVideobuzz
    this.WhatsNew = whatsNew
    this.AddAccount = youtube_add_account
    this.RedditSettings = EditRedditSettings
    this.TwitchSettings = EditTwitchSettings
    this.GeneralSettings = EditGeneralSettings
    this.ManageSubreddits = ManageSubreddits_impl
    this.ClearHistory = ClearHistory_impl

    ' History
    this.ShowHistory = ShowHistory_impl
    this.AddHistory = AddHistory_impl

    ' Initialize the history member, or else the ClearHistory function could fail below
    this.history = []

    ' Version of the history.
    ' Update when a new site is added, or when information stored in the registry might change
    this.HISTORY_VERSION = "11"
    regHistVer = RegRead( "HistoryVersion", "Settings" )
    if ( regHistVer = invalid OR regHistVer <> this.HISTORY_VERSION ) then
        print( "History version mismatch (clearing history), found: " + tostr( regHistVer ) + ", expected: " + this.HISTORY_VERSION )
        this.ClearHistory( false )
        RegWrite( "HistoryVersion", this.HISTORY_VERSION, "Settings" )
    end if

    ' TODO: Determine if this could be used for the reddit channel
    ' this.GetVideoDetails = GetVideoDetails_impl
    videosJSON = RegRead("videos", "history")
    this.historyLen = 0
    if ( videosJSON <> invalid AND isnonemptystr(videosJSON) ) then
        this.historyLen = Len(videosJSON)
        ' print("**** History string len: " + tostr(this.historyLen) + "****")
        this.history = ParseJson(videosJSON)
        if ( islist(this.history) = false ) then
            this.history = []
        end if
    end if

    ' LAN Videos related members
    this.dateObj = CreateObject( "roDateTime" )
    this.udp_socket = invalid
    this.mp_socket  = invalid
    this.udp_created = 0
    this.tcp_socket = invalid
    this.msgport_tcp = invalid
    this.tcp_created = 0
    this.connections = {}
    this.buffer = CreateObject("roByteArray")
    this.buffer[512] = 0
    this.dashManifestContents = invalid

    ' For Twitch Streaming Annoyance-fixing
    this.twitchM3U8URL = invalid

    patterns = {}
    ' patterns.split_or_join = CreateObject( "roRegex", "(\w+)=\1\.(?:split|join)\(" + Quote() + "" + Quote() + ")$", "" )
    patterns.func_call = CreateObject( "roRegex", "(\w+)=([$\w]+)\(((?:\w+,?)+)\)$", "")
    patterns.func_call_array = CreateObject( "roRegex", "([$\w]+)\[(\" + Quote() + "[$\w]+\" + Quote() + ")\]\(((?:\w+,?)+)\)$", "")
    patterns.split_or_join = CreateObject( "roRegex", "(\w+)=\1\.(?:split|join)\(" + Quote() + Quote() + "\)$", "")
    patterns.x1 =  CreateObject( "roRegex", "var\s(\w+)=(\w+)\[(\w+)\]$", "" )
    patterns.x2 = CreateObject( "roRegex", "(\w+)\[(\w+)\]=(\w+)\[(\w+)\%(\w+)\.length\]$", "" )
    patterns.x3 =  CreateObject( "roRegex", "(\w+)\[(\w+)\]=(\w+)$", "" )
    patterns.x4 = CreateObject( "roRegex", "(\w+)\[(\w+)\%(\w+)\.length\]=(\w+)$", "" )
    patterns.ret = CreateObject( "roRegex", "return (\w+)(\.join\(" + Quote() + Quote() + "\))?$", "" )
    patterns.reverse =  CreateObject( "roRegex", "(\w+)=(\w+)\.reverse\(\)$", "" )
    patterns.reverse_noass = CreateObject( "roRegex", "(\w+)\.reverse\(\)$", "" )
    patterns.return_reverse = CreateObject( "roRegex", "return (\w+)\.reverse\(\)$", "" )
    patterns.slice = CreateObject( "roRegex", "(\w+)=(\w+)\.slice\((\w+)\)$", "" )
    patterns.splice_noass = CreateObject( "roRegex", "([$\w]+)\.splice\(([$\w]+)\,([$\w]+)\)$", "" )
    patterns.return_slice = CreateObject( "roRegex", "return (\w+)\.slice\((\w+)\)$", "" )
    patterns.func_call_dict = CreateObject( "roRegex", "(\w)=([$\w]+)\.(?!slice|splice|reverse)([$\w]+)\(((?:\w+,?)+)\)$","" )
    patterns.func_call_dict_noret = CreateObject( "roRegex", "([$\w]+)\.(?!slice|splice|reverse)([$\w]+)\(((?:\w+,?)+)\)$", "" )

    this.patterns = patterns

    this.sleep_timer = -100
    this.audio_only = false
    this.WhatsNewLastQueried% = 0
    this.WhatsNewVideos = invalid
    ' Dialog used to show the app is working
    this.UpdateWaitDialog = updateWaitDialogText_impl
    this.CloseWaitDialog = closeWaitDialog_impl
    this.waitDialog = invalid
    return this
End Function

Sub GetWhatsNew_impl()
    dateObj = CreateObject( "roDateTime" )
    dateObj.Mark()
    curDateSecs% = dateObj.AsSeconds()
    twoDaysinSecs% = 172800
    prevDate = CreateObject( "roDateTime" )
    prevDate.FromSeconds( curDateSecs% - twoDaysinSecs% )
    twoDaysAgo = DateToISO8601String( prevDate, true )
    title = "What's New"
    screen = uitkPreShowPosterMenu( "flat-episodic-16x9", title )
    screen.showMessage( "Building list... this may take some time!" )
    ' Try to reduce queries, by limiting updates to only every 30 minutes
    if ( (curDateSecs% - m.WhatsNewLastQueried% > 1800) OR (m.WhatsNewVideos = invalid) )
        response = m.MySubscriptions()
        if ( response = invalid ) then
            ShowConnectionFailed()
            return
        end if
        subList = response.items
        ' Workaround for http://code.google.com/p/gdata-issues/issues/detail?id=7163
        response.nextPageToken = "CDIQAA"
        ' Add support for up to 100 subscriptions
        if ( response.nextPageToken <> invalid AND subList.Count() = 50 ) then
            screen.showMessage( "Querying second set of subscriptions..." )
            moreSubs = m.MySubscriptions( response.nextPageToken )
            if ( moreSubs <> invalid ) then
                for each subscription in moreSubs.items
                    subList.Push( subscription )
                end for
            else
                print ( "Invalid response from MySubscriptions")
            end if
        else
            print ( "No next page token.")
        end if

        m.WhatsNewVideos = []
        m.WhatsNewLastQueried% = curDateSecs%

        tempVids = []
        screen.showMessage( "Getting subscription activity..." )
        counter = 0
        for each item in subList
            vids = m.GetFilteredActivity( item.id, twoDaysAgo )
            counter = counter + 1
            screen.showMessage( "Getting subscription activity..." + toStr(counter) + " of " + toStr(subList.Count()) )
            if ( vids <> invalid ) then
                tempVids.Append( vids )
            end if
        end for

        if ( tempVids.Count() > 0 ) then
            print ("Getting video metadata for " + toStr( tempVids.Count() ) + " videos...")
            screen.showMessage( "Getting video metadata for " + toStr( tempVids.Count() ) + " videos..." )
            vidList = invalid
            bulkList = []
            while ( tempVids.Count() > 0 )
                bulkList.Push( tempVids.Pop() )
                if ( bulkList.Count() = 49 OR tempVids.Count() = 0 ) then
                    videoData = m.ExecBatchQueryV3( bulkList )
                    if ( videoData <> invalid ) then
                        if ( vidList = invalid ) then
                            vidList = videoData.items
                        else if ( videoData.items <> invalid ) then
                            for each item in videoData.items
                                vidList.Push( item )
                            end for
                        end if
                    end if
                    bulkList.Clear()
                end if
            end while
            if ( vidList <> invalid ) then
                videoListFromJSON = m.newVideoListFromJSON( vidList )
                metadata = GetVideoMetaData( videoListFromJSON )
                Sort( metadata, Function(vid as Object) as Integer
                        return vid.DateSeconds
                        End Function )
                while ( metadata.Count() > 100 )
                    metadata.Pop()
                end while

                title = title + " (" + toStr( metadata.Count() ) + " Videos)"
                screen.SetBreadcrumbText( title, "" )
                screen.SetTitle( title )
                m.WhatsNewVideos = metadata
            end if
        end if
    end if
    if ( m.WhatsNewVideos.Count() = 0 ) then
        ShowErrorDialog( "No activity in your subscriptions, check back later!", "Empty" )
    else
        m.DisplayVideoListFromVideoList(m.WhatsNewVideos, title, invalid, screen, invalid, Function(videos as Object) as Object
                                                                                 return videos
                                                                              End Function )
    end if
End Sub

Function buildIt( one, middle, ending ) as String
    result = ""
    arr = GetOne()
    for each item in arr
        result = result + Chr( item + one )
    end for

    arr = GetMid()
    for each item in arr
        result = result + Chr( item + middle )
    end for

    arr = GetEnd()
    for each item in arr
        result = result + Chr( item - ending )
    end for
    return result
End Function

Function ExecBatchQueryV3_impl( videoList as Object, mostPopular = false as Boolean, pageToken = invalid as Dynamic ) as Dynamic

    parms = []
    if ( mostPopular = false ) then
        strVideoIds = ""
        first = true
        for each video in videoList
            if ( first = false ) then
                strVideoIds = strVideoIds + ","
            end if
            strVideoIds = strVideoIds + video
            first = false
        end for
        parms.push( { name: "id", value: strVideoIds } )
    else
        parms.push( { name: "chart", value: "mostPopular" } )
    end if
    parms.push( { name: "part", value: "snippet,statistics,contentDetails" } )
    parms.push( { name: "maxResults", value: "49" } )
    parms.push( { name: "fields", value: "items(id,snippet(publishedAt,channelId,title,description,thumbnails,channelTitle),contentDetails(duration),statistics(likeCount,dislikeCount,viewCount)),nextPageToken,prevPageToken" } )
    if ( pageToken <> invalid ) then
        parms.push( { name: "pageToken", value: pageToken } )
    end if
    return m.BuildV3Request("videos", parms)
End Function

Function handleYoutubeError(rsp) As Dynamic
    ' Is there a status code? If not, return a connection error.
    if (rsp.status = invalid) then
        return ShowConnectionFailed( "handleYoutubeError" )
    end if
    ' Don't check for errors if the response code was a 2xx or 3xx number
    if (int(rsp.status / 100) = 2 OR int(rsp.status / 100) = 3) then
        return ""
    end if

    if (not(isxmlelement(rsp.xml))) then
        return ShowErrorDialog("API return invalid. Try again later", "Bad response")
    end if

    error = rsp.xml.GetNamedElements("error")[0]
    if (error = invalid) then
        ' we got an unformatted HTML response with the error in the title
        error = rsp.xml.GetChildElements()[0].GetChildElements()[0].GetText()
    else
        error = error.GetNamedElements("internalReason")[0].GetText()
    end if

    ShowDialog1Button("Error", error, "OK", true)
    return error
End Function

'********************************************************************
' YouTube User uploads
'********************************************************************
Sub BrowseUserVideos_impl(username As String, userID As String)
    if (Left(userID, 2) = "UC") then
        print "Viewing user videos via playlist items: " + "UU" + Mid(userID, 3)
        m.FetchVideoList( "GetPlaylistItems", "Videos By " + username, false, {contentArg: "UU" + Mid(userID, 3)})
    else
        m.FetchVideoList( "GetActivity", "Videos By " + username, false, {contentArg: userID})
    end if
End Sub

'********************************************************************
' YouTube User Playlists
'********************************************************************
Sub BrowseUserPlaylists_impl(username As String, userID As String)
    m.FetchVideoList( "GetPlaylists", username + "'s Playlists", true, {isPlaylist: true, itemFunc: "GetPlaylistItems", contentArg: userID} )
End Sub

Sub MostPopular_impl()
    m.FetchVideoList( "GetMostPopular", "Today's Most Popular Videos", false)
End Sub

Function GetMostPopular_impl( pageToken = invalid as Dynamic ) as Dynamic
    return m.ExecBatchQueryV3( invalid, true, pageToken )
End Function

'********************************************************************
' YouTube Poster/Video List Utils
'********************************************************************
Sub FetchVideoList_impl(contentFunc As Dynamic, title As String, isCategoryList = true As Boolean, categoryData = invalid as Dynamic, message = "Loading..." as String, useXMLTitle = false as Dynamic)

    'fields = m.FieldsToInclude
    'if Instr(0, APIRequest, "?") = 0 then
    '    fields = "?"+Mid(fields, 2)
    'end if

    screen = uitkPreShowPosterMenu("flat-episodic-16x9", title)
    screen.showMessage(message)
    contentArgument = invalid
    if ( categoryData <> invalid AND categoryData.contentArg <> invalid ) then
        contentArgument = categoryData.contentArg
        ' If the calling function doesn't ever intend to include page information...
        if ( categoryData.noPages = invalid ) then
            response = m[contentFunc]( categoryData.contentArg, categoryData.nextPageToken )
        else
            response = m[contentFunc]( categoryData.contentArg )
        end if
    else if ( categoryData <> invalid AND categoryData.nextPageToken <> invalid ) then
        response = m[contentFunc]( categoryData.nextPageToken )
    else
        response = m[contentFunc]()
    end if
    if (response = invalid) then
        ShowErrorDialog(title + " may be private, or unavailable at this time. Try again.", "Uh oh")
        return
    end if

    ' Everything is OK, display the list
    if ( isCategoryList = true ) then
        categoryData.categories = m.CategoriesListFromJSON( response.items, categoryData.itemFunc )
        if ( response.nextPageToken <> invalid ) then
            categoryData.categories.Push({title: "Load More",
                shortDescriptionLine1: "Load More Items",
                action: "next",
                nextPageToken: response.nextPageToken,
                contentFunc: contentFunc,
                itemFunc: categoryData.itemFunc,
                contentArg: categoryData.contentArg,
                screenTitle: title,
                origTitle: firstValid( categoryData["origTitle"], title ),
                depth: firstValid( categoryData["depth"], 1 ),
                isMoreLink: true,
                HDPosterUrl:"pkg:/images/icon_next_episode.jpg",
                SDPosterUrl:"pkg:/images/icon_next_episode.jpg"})
        end if
        m.DisplayVideoListFromVideoList( [], title, invalid, screen, categoryData )
    else
        if ( useXMLTitle = true AND response.title <> invalid ) then
            breadA = "Playlist"
            if ( response.snippet <> invalid AND response.snippet.channelTitle <> invalid ) then
                breadA = response.snippet.channelTitle
            end if
            screen.SetBreadcrumbText( breadA, "Playlist" )
        else
            newTitle = title
        end if
        videos = m.newVideoListFromJSON( response.items )
        if ( response.nextPageToken <> invalid ) then
            linkData = {}
            ytPageData = {}
            ytPageData.contentFunc = contentFunc
            ytPageData.contentArg = contentArgument
            ytPageData.nextPageToken = response.nextPageToken
            linkData.ytPageData = ytPageData
        else
            linkData = invalid
        end if
        m.DisplayVideoListFromVideoList( videos, newTitle, linkData, screen, invalid )
    end if

End Sub

Function BuildV3Request_impl(resource as String, additionalParams = invalid as Dynamic) as Object
    headers = {}
    http = NewHttp( m.v3Base + resource )
    http.AddParam( "key", m.stuff )
    if ( islist( additionalParams ) ) then
         for each e in additionalParams
            http.AddParam( e.name, e.value )
         next
    end if
    result = http.getToStringWithTimeout(10, headers)
    if (http.status = 403) then
        if (LCase(resource) = "subscriptions") then
            ShowErrorDialog("Request failed. Please go to https://www.youtube.com/account_privacy and ensure your subscriptions are public.", "Failed")
        else if (LCase(resource) = "playlists") then
            ShowErrorDialog("Request failed. Please go to YouTube, and ensure your playlists are public.", "Failed")
        else
            ShowErrorDialog("Request failed. YouTube returned '403 Forbidden,' try again later.", "Request Failed")
        end if
        return invalid
    end if
    if ( http.status = 200 ) then
        json = ParseJson( result )
        if ( json = invalid OR json.error <> invalid ) then
            ShowErrorDialog("Request failed, or YouTube is unavailable at this time. Try again.", "Request failed with 200")
            return invalid
        end if
        return json
    else
        ShowErrorDialog("Request failed, or YouTube is unavailable at this time. Try again.", "Response: " + tostr( http.status))
    end if
    return invalid
End Function

Function GetActivity_impl( forChannelId as String, pageToken = invalid as Dynamic ) as Dynamic
    parms = []
    parms.push( { name: "part", value: "snippet" } )
    parms.push( { name: "order", value: "date" } )
    parms.push( { name: "safeSearch", value: "none" } )
    parms.push( { name: "type", value: "video" } )
    parms.push( { name: "channelId", value: forChannelId } )
    parms.push( { name: "maxResults", value: "50" } )
    parms.push( { name: "fields", value: "items(id(videoId)),nextPageToken,prevPageToken" } )
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
            result = m.ExecBatchQueryV3( vids )
            result.nextPageToken = resp.nextPageToken
            result.prevPageToken = resp.prevPageToken
            return result
        end if
    end if
    return invalid
End Function

Function GetFilteredActivity_impl( forChannelId as String, fromDate as String ) as Dynamic
    parms = []
    parms.push( { name: "part", value: "snippet,contentDetails" } )
    parms.push( { name: "channelId", value: forChannelId } )
    parms.push( { name: "maxResults", value: "49" } )
    parms.push( { name: "publishedAfter", value: fromDate } )
    parms.push( { name: "fields", value: "items(contentDetails(upload(videoId)),snippet(publishedAt))" } )

    ' Get activity
    resp = m.BuildV3Request("activities", parms)
    vids = []
    if ( resp <> invalid ) then
        for each item in resp.items
            'if ( item.snippet.type = "upload" ) then
            if ( item.contentDetails <> invalid AND item.contentDetails.upload <> invalid AND item.contentDetails.upload.videoId <> invalid ) then
                vids.Push( item.contentDetails.upload.videoId )
            end if
        end for
        if ( vids.Count() > 0 ) then
            return vids
        end if
    end if
    return invalid
End Function

' From TheEndless via the Roku Development Forums
Function DateToISO8601String(date As Object, includeZ = True As Boolean) As String
   iso8601 = PadLeft(date.GetYear().ToStr(), "0", 4)
   iso8601 = iso8601 + "-"
   iso8601 = iso8601 + PadLeft(date.GetMonth().ToStr(), "0", 2)
   iso8601 = iso8601 + "-"
   iso8601 = iso8601 + PadLeft(date.GetDayOfMonth().ToStr(), "0", 2)
   iso8601 = iso8601 + "T"
   iso8601 = iso8601 + PadLeft(date.GetHours().ToStr(), "0", 2)
   iso8601 = iso8601 + ":"
   iso8601 = iso8601 + PadLeft(date.GetMinutes().ToStr(), "0", 2)
   iso8601 = iso8601 + ":"
   iso8601 = iso8601 + PadLeft(date.GetSeconds().ToStr(), "0", 2)
   if ( includeZ ) then
      iso8601 = iso8601 + "Z"
   end if
   return iso8601
End Function

' From TheEndless via the Roku Development Forums
Function PadLeft(value As String, padChar As String, totalLength As Integer) As String
   while ( value.Len() < totalLength )
      value = padChar + value
   end while
   return value
End Function

Function MySubscriptions_impl( pageToken = invalid as Dynamic ) as Dynamic
    parms = []
    parms.push( { name: "part", value: "snippet,contentDetails" } )
    parms.push( { name: "channelId", value: m.channelId } )
    parms.push( { name: "maxResults", value: "50" } )
    parms.push( { name: "order", value: "unread" } )
    parms.push( { name: "fields", value: "items(id,snippet(title,resourceId),contentDetails),nextPageToken" } )
    if ( pageToken <> invalid ) then
        parms.push( { name: "pageToken", value: pageToken } )
    end if
    ' Get List of Subscriptions
    result = m.BuildV3Request("subscriptions", parms)
    if (result <> invalid) then
        for each item in result.items
            item.id = item.snippet.resourceId.channelId
        end for
    end if

    return result
End Function

Function GetVideosActivity_impl( channelId as String, pageToken = invalid as Dynamic ) as Dynamic
    if (Left(channelId, 2) = "UC") then
        print "Getting subscription videos via playlist items: " + "UU" + Mid(channelId, 3)
        return m.GetPlaylistItems( "UU" + Mid(channelId, 3), pageToken)
    else
        return m.GetActivity( channelId, pageToken )
    end if
End Function

Function MyPlaylists_impl( pageToken = invalid as Dynamic ) as Dynamic
    return m.GetPlaylists( m.channelId, pageToken )
End Function

Function GetPlaylists_impl( forChannelId as String, pageToken = invalid as Dynamic ) as Dynamic
    parms = []
    parms.push( { name: "part", value: "snippet" } )
    parms.push( { name: "channelId", value: forChannelId } )
    parms.push( { name: "maxResults", value: "49" } )
    parms.push( { name: "fields", value: "items(id,snippet(title)),nextPageToken" } )
    if ( pageToken <> invalid ) then
        parms.push( { name: "pageToken", value: pageToken } )
    end if
    ' Get List of Playlists
    return m.BuildV3Request("playlists", parms)
End Function

Function GetPlaylistItems_impl( playlistId as String, pageToken = invalid as Dynamic ) as Object
    parms = []
    parms.push( { name: "part", value: "snippet" } )
    parms.push( { name: "playlistId", value: playlistId } )
    parms.push( { name: "maxResults", value: "50" } )
    parms.push( { name: "fields", value: "items(snippet(resourceId)),nextPageToken,prevPageToken" } )
    if ( pageToken <> invalid ) then
        parms.push( { name: "pageToken", value: pageToken } )
    end if
    ' Get List of Playlists
    resp = m.BuildV3Request("playlistItems", parms)
    if ( resp <> invalid AND resp.items <> invalid ) then
        vids = []
        for each item in resp.items
            vids.Push( item.snippet.resourceId.videoId )
        end for
        retVal = m.ExecBatchQueryV3( vids )
        retVal.nextPageToken = resp.nextPageToken
        retVal.prevPageToken = resp.prevPageToken
        return retVal
    end if
    return invalid
End Function

Function ReturnVideoList_impl(listFunction as String, listFunctionArg as String, pageToken = invalid as Dynamic)
    response = m[listFunction]( listFunctionArg, pageToken )
    if (response = invalid) then
        return invalid
    end if
    videos = m.newVideoListFromJSON( response.items )
    metadata = GetVideoMetaData(videos)

    if ( response.nextPageToken <> invalid ) then
        ytPageData = {}
        ytPageData.contentFunc = listFunction
        ytPageData.contentArg = listFunctionArg
        ytPageData.pageToken = response.nextPageToken
        metadata.Push({shortDescriptionLine1: "More Results", action: "next", linkData: ytPageData, HDPosterUrl:"pkg:/images/icon_next_episode.jpg", SDPosterUrl:"pkg:/images/icon_next_episode.jpg"})
    end if

    if ( response.prevPageToken <> invalid ) then
        ytPageData = {}
        ytPageData.contentFunc = listFunction
        ytPageData.contentArg = listFunctionArg
        ytPageData.pageToken = response.prevPageToken
        metadata.Unshift({shortDescriptionLine1: "Back", action: "prev", linkData: ytPageData, HDPosterUrl:"pkg:/images/icon_prev_episode.jpg", SDPosterUrl:"pkg:/images/icon_prev_episode.jpg"})
    end if
    return metadata
End Function

Sub DisplayVideoListFromVideoList_impl(videos As Object, title As String, links=invalid, screen = invalid, categoryData = invalid as Dynamic, metadataFunc = GetVideoMetaData as Function)
    if (categoryData = invalid) then
        metadata = metadataFunc(videos)
    else
        metadata = videos
    end if
    m.DisplayVideoListFromMetadataList(metadata, title, links, screen, categoryData)
End Sub

Sub DisplayVideoListFromMetadataList_impl(metadata As Object, title As String, linkData = invalid as Dynamic, screen = invalid, categoryData = invalid)
    if (screen = invalid) then
        screen = uitkPreShowPosterMenu("flat-episodic-16x9", title)
        screen.showMessage("Loading...")
    end if
    previousTitle = m.CurrentPageTitle
    m.CurrentPageTitle = title

    if (categoryData <> invalid) then
        categoryList = CreateObject("roArray", 100, true)
        for each category in categoryData.categories
            categoryList.Push(category.title)
        next

        oncontent_callback = [categoryData.categories, m,
            function(categories, youtube, set_idx)
                'PrintAny(0, "category:", categories[set_idx])
                if (youtube <> invalid AND categories.Count() > 0 AND categories[set_idx]["action"] = invalid ) then
                    return youtube.ReturnVideoList( categories[set_idx].itemFunc, categories[set_idx].id )
                else
                    return []
                end if
            end function]

        onclick_callback = [categoryData.categories, m,
            function(categories, youtube, video, category_idx, set_idx)
                if (video[set_idx]["action"] <> invalid) then
                    'additionalParams = []
                    'additionalParams.push( { name: "safeSearch", value: "none" } )
                    return { isContentList: true, content: youtube.ReturnVideoList( video[set_idx]["linkData"]["contentFunc"], video[set_idx]["linkData"]["contentArg"], video[set_idx]["linkData"]["pageToken"] ) }
                else
                    vidIdx% = youtube.VideoDetails(video[set_idx], youtube.CurrentPageTitle, video, set_idx)
                    return { isContentList: false, content: video, vidIdx: vidIdx%}
                end if
            end function]
        uitkDoCategoryMenu( categoryList, screen, oncontent_callback, onclick_callback, onplay_callback, categoryData.isPlaylist )
    else if (metadata.Count() > 0) then
        if ( linkData <> invalid ) then
            if (type(linkData) = "roAssociativeArray") then
                link = linkData.next
                if (link <> invalid) then
                    metadata.Push({shortDescriptionLine1: "More Results", action: "next", pageURL: link.href, HDPosterUrl:"pkg:/images/icon_next_episode.jpg", SDPosterUrl:"pkg:/images/icon_next_episode.jpg", func: link.func})
                end if
                link = linkData.previous
                if (link <> invalid) then
                    metadata.Unshift({shortDescriptionLine1: "Back", action: "prev", pageURL: link.href, HDPosterUrl:"pkg:/images/icon_prev_episode.jpg", SDPosterUrl:"pkg:/images/icon_prev_episode.jpg", func: link.func})
                end if
                link = linkData.ytPageData
                if (link <> invalid) then
                    metadata.Push({shortDescriptionLine1: "More Results", action: "next", linkData: link, HDPosterUrl:"pkg:/images/icon_next_episode.jpg", SDPosterUrl:"pkg:/images/icon_next_episode.jpg"})
                end if
            end if
        end if
        onselect = [1, metadata, m,
            function(video, youtube, set_idx)
                retVal% = 0
                if (video[set_idx]["func"] <> invalid) then
                    video[set_idx]["func"](youtube, video[set_idx]["pageURL"])
                else if (video[set_idx]["action"] <> invalid) then
                    youtube.FetchVideoList(video[set_idx]["linkData"]["contentFunc"], youtube.CurrentPageTitle, false, video[set_idx]["linkData"])
                else
                    retVal% = youtube.VideoDetails(video[set_idx], youtube.CurrentPageTitle, video, set_idx)
                end if
                return retVal%
            end function]
        uitkDoPosterMenu(metadata, screen, onselect, onplay_callback)
    else
        uitkDoMessage("No videos found.", screen)
    end if
    m.CurrentPageTitle = previousTitle
End Sub

'********************************************************************
' Callback function for when the user hits the play button from the video list
' screen.
' @param theVideo the video metadata object that should be played.
'********************************************************************
Sub onplay_callback(theVideo as Object)
    getYoutube().UpdateWaitDialog( "Playing Video..." )
    result = video_get_qualities(theVideo)
    getYoutube().CloseWaitDialog()
    if (result = 0) then
        DisplayVideo(theVideo)
    end if
End Sub

'********************************************************************
' Creates the list of categories from the provided JSON
' @param xmlList the XML to create the category list from.
' @return an roList, which will be sorted by the yt:unreadCount if the XML
'         represents a list of subscriptions.
'         each category has the following members:
'           title
'           link
'********************************************************************
Function CategoriesListFromJSON_impl(jsonList As Object, itemFunc as String) As Object
    categoryList  = CreateObject("roList")
    for each record in jsonList
        category            = {}
        category.title  = record.snippet.title
        category.id = record.id
        category.itemFunc = itemFunc
        categoryList.Push(category)
    end for

    return categoryList
End Function

'********************************************************************
' Creates a list of video metadata objects from the provided XML
' @param xmlList the XML to create the list of videos from
' @return an roList of video metadata objects
'********************************************************************
Function newVideoListFromJSON_impl(jsonList As Object) As Object
    'print "newVideoListFromJSON_impl init"
    videolist = CreateObject("roList")
    for each record in jsonList
        video = m.newVideoFromJSON( record )
        if ( video <> invalid ) then
            videolist.Push( video )
        end if
    next
    return videolist
End Function

Function newVideoFromJSON_impl(jsonVideoItem as Object) As Dynamic
    if jsonVideoItem.Lookup("contentDetails") = invalid then
        return invalid
    end if
    video                   = CreateObject("roAssociativeArray")
    video["ID"]             = jsonVideoItem.id
    video["Author"]         = jsonVideoItem.snippet.channelTitle
    video["UserID"]         = jsonVideoItem.snippet.channelId
    video["Title"]          = jsonVideoItem.snippet.title
    video["Linked"]         = MatchAll( getRegexes().ytIDRegexForDesc, jsonVideoItem.snippet.description )
    video["Description"]    = jsonVideoItem.snippet.description
    video["Length"]         = get_human_readable_as_length( jsonVideoItem.contentDetails.duration )
    video["UploadDate"]     = GetUploadDate_impl( jsonVideoItem.snippet.publishedAt )
    video["DateSeconds"]    = GetUploadSeconds_impl( jsonVideoItem.snippet.publishedAt )
    if (jsonVideoItem.statistics <> invalid AND jsonVideoItem.statistics.viewCount <> invalid) then
        video["Category"]       = jsonVideoItem.statistics.viewCount + " Views"
    else
        video["Category"]       = "Unknown Views"
    end if
    video["Rating"]         = invalid
    if (jsonVideoItem.statistics <> invalid AND jsonVideoItem.statistics.likeCount <> invalid AND jsonVideoItem.statistics.dislikeCount <> invalid AND jsonVideoItem.statistics.likeCount.Toint() > 0) then
        video["Rating"] = Int(jsonVideoItem.statistics.likeCount.ToFloat() / (jsonVideoItem.statistics.likeCount.ToFloat() + jsonVideoItem.statistics.dislikeCount.ToFloat()) * 100)
    end if
    video["Thumb"]          = firstValid( jsonVideoItem.snippet.thumbnails.medium.url, jsonVideoItem.snippet.thumbnails.default.url, "" )
    return video
End Function

Function GetVideoMetaData(videos As Object)
    metadata = []
    constants = getConstants()
    for each video in videos
        meta = CreateObject("roAssociativeArray")
        meta.ContentType = "movie"

        meta["ID"]                     = video["ID"]
        meta["Author"]                 = video["Author"]
        meta["TitleSeason"]            = video["Title"]
        meta["Title"]                  = video["Author"] + "  - " + get_length_as_human_readable(video["Length"])
        meta["Actors"]                 = meta["Author"]
        meta["FullDescription"]        = video["Description"]
        meta["Description"]            = Left( video["Description"], 300 )
        meta["Categories"]             = video["Category"]
        meta["StarRating"]             = video["Rating"]
        meta["ShortDescriptionLine1"]  = meta["TitleSeason"]
        meta["ShortDescriptionLine2"]  = meta["Title"]
        meta["SDPosterUrl"]            = video["Thumb"]
        meta["HDPosterUrl"]            = video["Thumb"]
        meta["Length"]                 = video["Length"]
        meta["UserID"]                 = video["UserID"]
        meta["ReleaseDate"]            = video["UploadDate"]
        meta["DateSeconds"]            = video["DateSeconds"]
        meta["StreamFormat"]           = "mp4"
        meta["Live"]                   = false
        meta["Streams"]                = []
        meta["Linked"]                 = video["Linked"]
        meta["Source"]                 = video["Source"]
        meta["PlayStart"]              = 0
        meta["SwitchingStrategy"]      = "no-adaptation"
        meta["Source"]                 = constants.sYOUTUBE

        metadata.Push(meta)
    end for

    return metadata
End Function

Function GetMid() as Dynamic
    retVal = []
    retVal.Push( 40 )
    retVal.Push( 82 )
    retVal.Push( 61 )
    retVal.Push( 56 )
    retVal.Push( 24 )
    retVal.Push( 65 )
    retVal.Push( 72 )
    retVal.Push( 72 )
    retVal.Push( 90 )
    retVal.Push( 43 )
    retVal.Push( 53 )
    retVal.Push( 73 )
    retVal.Push( 23 )
    retVal.Push( 73 )

    return retVal
End Function

'*******************************************
'  Returns the date the video was uploaded, from the yt:uploaded element:
'  <yt:uploaded>val</yt:uploaded>
'*******************************************
Function GetUploadDate_impl(dateString as String) As Dynamic
    'dateObj = CreateObject("roDateTime")
    ' The value from YouTube has a 'Z' at the end, we need to strip this off, or else
    ' FromISO8601String() can't parse the date properly
    'dateObj.FromISO8601String(Left(dateText, Len(dateText) - 1))
    'return tostr(dateObj.GetMonth()) + "/" + tostr(dateObj.GetDayOfMonth()) + "/" + tostr(dateObj.GetYear())
    return Left(dateString, 10)
End Function

Function GetUploadSeconds_impl(dateText as String) As Dynamic
    dateObj = CreateObject("roDateTime")
    ' The value from YouTube has a 'Z' at the end, we need to strip this off, or else
    ' FromISO8601String() can't parse the date properly
    dateObj.FromISO8601String(Left(dateText, Len(dateText) - 1))
    return dateObj.AsSeconds()
End Function

'*******************************************
'  Returns the length of the video in a human-friendly format
'  i.e. 3700 seconds becomes: 1h 1m 40s
'*******************************************
Function get_length_as_human_readable(length As Dynamic) As String
    if (type(length) = "roString") then
        len% = length.ToInt()
    else if (type(length) = "roInteger") then
        len% = length
    else
        return "Unknown"
    end if

    if ( len% > 0 ) then
        hours%   = FIX(len% / 3600)
        len% = len% - (hours% * 3600)
        minutes% = FIX(len% / 60)
        seconds% = len% MOD 60
        if ( hours% > 0 ) then
            return Stri(hours%) + "h" + Stri(minutes%) + "m"
        else
            return Stri(minutes%) + "m" + Stri(seconds%) + "s"
        end if
    else if ( len% = 0 ) then
        return "Live Stream"
    end if
    ' Default return
    return "Unknown"
End Function

'*******************************************
'  Returns the length of the video in seconds
'  i.e. 1h1m becomes 3660 seconds
'*******************************************
Function get_human_readable_as_length(length As Dynamic) As Integer
    len% = 0
    regexes = getRegexes()
    hourMatches = regexes.regexTimestampHours.Match( length )
    if ( hourMatches.Count() = 2 ) then
        len% = len% + (3600 * strtoi( hourMatches[1] ))
    end if

    minuteMatches = regexes.regexTimestampMinutes.Match( length )
    if ( minuteMatches.Count() = 2 ) then
        len% = len% + (60 * strtoi( minuteMatches[1] ))
    end if

    secMatches = regexes.regexTimestampSeconds.Match( length )
    if ( secMatches.Count() = 2 ) then
        len% = len% + strtoi( secMatches[1] )
    end if
    return len%
End Function

'********************************************************************
' YouTube video details roSpringboardScreen
'********************************************************************
Function VideoDetails_impl(theVideo As Object, breadcrumb As String, videos=invalid, idx=invalid) as Integer
    p = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(p)

    activeVideo = theVideo
    screen.SetDescriptionStyle("movie")
    if ( activeVideo["StarRating"] = invalid ) then
        screen.SetStaticRatingEnabled( false )
    end if
    vidCount = videos.Count()
    if ( vidCount > 1 ) then
        screen.AllowNavLeft( true )
        screen.AllowNavRight( true )
    end if
    screen.SetPosterStyle( "rounded-rect-16x9-generic" )
    screen.SetDisplayMode( "zoom-to-fill" )
    screen.SetBreadcrumbText( breadcrumb, "Video" )

    BuildButtons( activeVideo, screen )

    screen.SetContent( theVideo )
    screen.Show()

    while (true)
        msg = wait( 2000, screen.GetMessagePort() )
        if ( type( msg ) = "roSpringboardScreenEvent" ) then
            if ( msg.isScreenClosed() ) then
                'print "Closing springboard screen"
                exit while
            else if ( msg.isButtonPressed() ) then
                'print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                if ( msg.GetIndex() = 0 ) then ' Play/Resume
                    getYoutube().UpdateWaitDialog( "Playing Video..." )
                    result = video_get_qualities( activeVideo )
                    getYoutube().CloseWaitDialog()
                    if ( result = 0 ) then
                        DisplayVideo( activeVideo )
                        BuildButtons( activeVideo, screen )
                    end if
                else if ( msg.GetIndex() = 1 ) then ' Play All
                    for i = idx to vidCount - 1  Step +1
                        selectedVideo = videos[i]
                        isPlaylist = firstValid( selectedVideo["isPlaylist"], false )
                        if ( isPlaylist = false AND selectedVideo["action"] = invalid )
                            getYoutube().UpdateWaitDialog( "Playing Video..." )
                            result = video_get_qualities( selectedVideo )
                            getYoutube().CloseWaitDialog()
                            if ( result = 0 ) then
                                activeVideo = videos[i]
                                ret = DisplayVideo( activeVideo )
                                BuildButtons( activeVideo, screen )
                                screen.SetContent( activeVideo )
                                idx = i
                                if ( ret > 0 ) then
                                    Exit For
                                end if
                            end if
                        end if
                    end for
                else if ( msg.GetIndex() = 2 ) then ' Show related videos
                    m.FetchVideoList( "FindRelated", "Related Videos", false, {contentArg: activeVideo["ID"]} )
                else if ( msg.GetIndex() = 3 ) then ' Show user's videos
                    m.BrowseUserVideos( activeVideo["Author"], activeVideo["UserID"] )
                else if ( msg.GetIndex() = 4 ) then ' Show user's playlists
                    m.BrowseUserPlaylists( activeVideo["Author"], activeVideo["UserID"] )
                else if ( msg.GetIndex() = 5 ) then ' Play from beginning
                    activeVideo["PlayStart"] = 0
                    getYoutube().UpdateWaitDialog( "Playing Video..." )
                    result = video_get_qualities( activeVideo )
                    getYoutube().CloseWaitDialog()
                    if (result = 0) then
                        DisplayVideo( activeVideo )
                        BuildButtons( activeVideo, screen )
                    end if
                else if ( msg.GetIndex() = 6 ) then ' Linked videos
                    m.FetchVideoList( "ExecBatchQueryV3", "Linked Videos", false, { contentArg: activeVideo["Linked"], noPages: true} )
                else if (msg.GetIndex() = 7) then ' View playlist
                    if ( activeVideo["Source"] = GetConstants().sYOUTUBE ) then
                        ' Handle when the Video Details screen is being shown with the 'View Playlist' menu item only.
                        if ( firstValid( activeVideo["IsPlaylist"], false ) = true ) then
                            m.FetchVideoList( "GetPlaylistItems", activeVideo["TitleSeason"], false, {contentArg: activeVideo["PlaylistID"]}, "Loading playlist...", true)
                        else
                            plId = activeVideo["PlaylistID"]
                            if ( plId <> invalid ) then
                                m.FetchVideoList( "GetPlaylistItems", activeVideo[ "TitleSeason" ], false, {contentArg: plId}, "Loading playlist...", true )
                            else
                                print "Couldn't find playlist id for URL: " ; activeVideo["URL"]
                            end if
                        end if
                    else if ( activeVideo["Source"] = GetConstants().sGOOGLE_DRIVE ) then
                        getGDriveFolderContents( activeVideo )
                    end if
                end if
            else if ( msg.isRemoteKeyPressed() ) then
                if ( msg.GetIndex() = 4 AND vidCount > 1 ) then  ' left arrow
                    idx = idx - 1
                    ' Check to see if the first video is an 'Action' button
                    if ( (idx < 0) OR (idx = 0 AND videos[idx]["action"] <> invalid) ) then
                        ' Set index to last video
                        idx = vidCount - 1
                    end if
                    ' Now check to see if the last video is an 'Action' button
                    if ( idx = vidCount - 1 AND videos[idx]["action"] <> invalid ) then
                        ' Last video is the 'next' video link, so move the index one more to the left
                         idx = idx - 1
                    end if
                    activeVideo = videos[idx]
                    BuildButtons( activeVideo, screen )
                    screen.SetContent( activeVideo )
                else if ( msg.GetIndex() = 5 AND vidCount > 1 ) then ' right arrow
                    idx = idx + 1
                    ' Check to see if the last video is an "Action" button
                    if ( (idx = vidCount) OR (idx = vidCount - 1 AND videos[idx]["action"] <> invalid) ) then
                        ' Last video is the 'next' video link
                        idx = 0
                    end if
                    ' Now check to see if the first video is an 'Action' button
                    if ( idx = 0 AND videos[idx]["action"] <> invalid ) then
                        ' First video is the 'Back' video link, so move the index one more to the right
                         idx = idx + 1
                    end if
                    activeVideo = videos[idx]
                    BuildButtons( activeVideo, screen )
                    screen.SetContent( activeVideo )
                end if
            else if ( msg.isButtonInfo() ) then
                while ( VListOptionDialog( activeVideo ) = 1 )
                end while
            else
                'print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage() ; " index: " ; tostr(msg.GetIndex()) ; " data: " ; tostr(msg.GetData())
                'if (msg.GetInfo() <> invalid) then
                '    PrintAny(0, "More Info", msg.GetInfo() )
                'end if
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end If
    end while
    return idx
End Function

'********************************************************************
' Helper function to build the list of buttons on the springboard
'********************************************************************
Sub BuildButtons( activeVideo as Object, screen as Object )
    screen.ClearButtons()
    resumeEnabled = false
    isPlaylist = firstValid( activeVideo[ "isPlaylist" ], false )
    videoAuthor = activeVideo[ "Author" ]
    viewPlaylistButtonAdded = false
    if ( isPlaylist = false ) then
        if ( firstValid( activeVideo[ "Live" ], false ) = false AND firstValid( activeVideo[ "PlayStart" ], 0 ) > 0 ) then
            resumeEnabled = true
            screen.AddButton( 0, "Resume" )
            screen.AddButton( 5, "Play from beginning" )
        else
            screen.AddButton( 0, "Play")
        end if
        screen.AddButton( 1, "Play All")
    else
        screen.AddButton( 7, "View Playlist" )
        viewPlaylistButtonAdded = true
    end if
    if ( videoAuthor <> invalid) then
        ' Hide related videos if the Resume/Play from beginning options are enabled
        if ( not( resumeEnabled ) ) then
            screen.AddButton( 2, "Show Related Videos" )
        end if
        screen.AddButton( 3, "More Videos By " + videoAuthor )
        screen.AddButton( 4, "Show "+ videoAuthor + "'s playlists" )
    end if
    if ( activeVideo[ "Linked" ] <> invalid AND activeVideo[ "Linked" ].Count() > 0) then
        screen.AddButton( 6, "Linked Videos" )
    end if
    if ( viewPlaylistButtonAdded = false AND firstValid( activeVideo[ "HasPlaylist" ], false ) = true AND screen.CountButtons() < 6 ) then
        screen.AddButton( 7, "View Playlist" )
    end if
End Sub

'********************************************************************
' The video playback screen
'********************************************************************
Function DisplayVideo(content As Object)
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    video.SetPositionNotificationPeriod(5)

    yt = getYoutube()
    ' Need to add the SSL cert to the video screen if in https
    if ( content["SSL"] = true ) then
        video.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
        video.SetCertificatesDepth( 3 )
        video.InitClientCertificates()
    end if
    video.AddHeader( "User-Agent", getConstants().USER_AGENT )
    video.SetContent(content)
    video.show()
    ret = -1
    waitTime = 0
    isLocalServer = false
    if ( yt.dashManifestContents <> invalid ) then
        waitTime = 1000
        isLocalServer = true
    end if
    while (true)
        msg = wait(waitTime, video.GetMessagePort())
        if (type(msg) = "roVideoScreenEvent") then
            if (Instr(1, msg.getMessage(), "interrupted") > 0) then
                ret = 1
            end if
            if (msg.isScreenClosed()) then 'ScreenClosed event
                'print "Closing video screen"
                video.Close()
                exit while
            else if (msg.isRequestFailed()) then
                print "play failed: " ; msg.GetMessage() ; + " Code: " + toStr( msg.GetIndex() )
                'print "video URL: " ; content["Streams"][0].url
                if ((msg.GetIndex() = -5 OR msg.GetIndex() = -1 OR msg.GetIndex() = -3) AND content["StreamFormat"] <> invalid AND content["StreamFormat"] = "dash") then
                    content["FailedDash"] = true
                    ShowErrorDialog( "DASH playback failed, try again.", "DASH Playback Error")
                else
                    ShowErrorDialog( "Video playback failed (Code: " + toStr( msg.GetIndex() ) + ")", "Unknown Playback Error")
                end if
            else if (msg.isPlaybackPosition()) then
                content["PlayStart"] = msg.GetIndex()
                if ( yt.sleep_timer <> -100 AND msg.GetIndex() <> 0 ) then
                    yt.sleep_timer = yt.sleep_timer - 5
                    if ( yt.sleep_timer < 0 ) then
                        print( "Sleepy time" )
                        yt.sleep_timer = -100
                        video.Close()
                        ' Set the return value so that 'Play All' won't continue if the sleep timer elapses
                        ret = 2
                        sleepyDialog = ShowDialogNoButton( "Sleep Timer Expired", "" )
                        sleep( 3000 )
                        sleepyDialog.Close()
                        exit while
                    end if
                else
                    ' CheckForMCast()
                end if
            else if (msg.isFullResult()) then
                content["PlayStart"] = 0
            else if (msg.isPartialResult()) then
                ' For plugin videos, the Length may not be available.
                if (content.Length <> invalid) then
                    ' If we're within 30 seconds of the end of the video, don't allow resume
                    if (content["PlayStart"] > (content["Length"] - 30)) then
                        content["PlayStart"] = 0
                    end if
                end if
                ' Else if the length isn't valid, always allow resume
            else
                'print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        else if (msg = invalid AND isLocalServer = true) then
            CheckForUnicast()
        end if
    end while
    ' Add the video to history
    yt.AddHistory(content)
    ' Reset here so we don't attempt to play the stale contents again
    yt.dashManifestContents = invalid
    yt.twitchM3U8URL = invalid
    return ret
End Function

Function getYouTubeMP4Url(video as Object, doDASH = true as Boolean, retryCount = 0 as Integer ) as Object
    video["Streams"].Clear()
    isSSL = false
    prefs = getPrefs()
    DASH_MAX_RETRIES = 1
    if (video["FailedDash"] <> invalid) then
        print "FailedDash was not invalid, playing mp4"
        doDASH = false
    else if (doDASH = true AND prefs.getPrefValue( getConstants().pVIDEO_QUALITY ) = getConstants().FORCE_LOWEST) then
        print "Not getting DASH due to preference being set to lowest quality."
        doDASH = false
    else if (video["Length"] = 0) then
        print "Not using DASH for live stream"
        doDASH = false
    else if ( doDASH = true AND retryCount > DASH_MAX_RETRIES ) then
        doDASH = false
        retryCount = 0
        print "Not using DASH due to too many retries"
    end if
    if (Left(LCase(video["ID"]), 4) = "http") then
        url = video["ID"]
        if ( Left( LCase( url ), 5) = "https" ) then
            isSSL = true
        end if
    else if (doDASH = true) then
        ' el = adunit, detailpage, editpage, embedded, previewpage, profilepage,
        ' No dashmpd with protected: leanback
        ' Includes dashmpd, but doesn't work with protected: unplugged
        'url = "http://www.youtube.com/get_video_info?el=info&video_id=" + video["ID"]
        if (retryCount = 0) then
            url = "https://www.youtube.com/get_video_info?el=detailpage&video_id=" + video["ID"]
            if (getYoutube().STSVal <> invalid) then
                url = url + "&sts=" + getYoutube().STSVal
            end if
        else if (retryCount = DASH_MAX_RETRIES) then
            url = "https://www.youtube.com/embed/" + video["ID"]
            isSSL = true
        end if
    else if (retryCount = 0) then
        url = "https://www.youtube.com/get_video_info?el=detailpage&video_id=" + video["ID"]
        if (getYoutube().STSVal <> invalid) then
            url = url + "&sts=" + getYoutube().STSVal
        end if
    else if (retryCount = 1) then
        url = "https://www.youtube.com/get_video_info?disable_polymer=true&video_id=" + video["ID"] + "&eurl=https://youtube.googleapis.com/v/" + video["ID"]
        isSSL = true
        if (getYoutube().STSVal <> invalid) then
            url = url + "&sts=" + getYoutube().STSVal
        end if
    end if
    constants = getConstants()
    port = CreateObject("roMessagePort")
    getYoutube().UpdateWaitDialog( "Downloading info webpage..." )
    http = NewHttp( url )
    headers = { }
    headers["User-Agent"] = constants.USER_AGENT
    headers["Cookie"] = ""
    htmlString = http.getToStringWithTimeout(10, headers)

    if ( http.status <> -1 AND http.status <> 403 ) then
        if (doDASH = true) then
            getYoutube().UpdateWaitDialog( "Attempting to load DASH format..." )
            retVal = getYouTubeDASHMPD( htmlString, video, isSSL )

            ' If the get DASH MPD URL fails, then fall back to the old way.
            if ( retVal = invalid ) then
                ' invalid means the get_js_sm function reported that the STS value changed, retry.
                getYouTubeMP4Url( video, doDASH, retryCount )
            else if ( retVal.Count() = 0  ) then
                if ( retryCount >= DASH_MAX_RETRIES ) then
                    print "Failed to find DASH MPD URL, attempting fall-back."
                    doDASH = false
                    retryCount = 0
                else
                    ' Retry with second URL
                    getYouTubeMP4Url( video, doDASH, retryCount + 1 )
                end if
            end if
        end if
        if (doDASH = false) then
            if ( getYouTubeOrGDriveURLs( htmlString, video, isSSL, retryCount ) = invalid ) then
                ' invalid means the get_js_sm function reported that the STS value changed, retry.
                getYouTubeMP4Url( video, doDASH, retryCount )
            end if
        end if
    else
        print "HTTP Request returned " + toStr( http.status ) + " in getYouTubeMP4Url"
    end if
    return video["Streams"]
End Function

Function dashManifest( videoID as String, formatData, duration )
    youtube = getYoutube()
    MPDString = "<?xml version=" + Quote() + "1.0" + Quote() + " encoding=" + Quote() + "UTF-8" + Quote() + "?>"
    MPDString = MPDString + "<MPD xmlns:xsi=" + Quote() + "http://www.w3.org/2001/XMLSchema-instance" + Quote() + " xmlns=" + Quote() + "urn:mpeg:DASH:schema:MPD:2011" + Quote() + " xmlns:yt=" + Quote() + "http://youtube.com/yt/2012/10/10" + Quote() + " xsi:schemaLocation=" + Quote() + "urn:mpeg:DASH:schema:MPD:2011 DASH-MPD.xsd" + Quote() + " minBufferTime=" + Quote() + "PT5.500S" + Quote() + " profiles=" + Quote() + "urn:mpeg:dash:profile:isoff-on-demand:2011" + Quote() + " type=" + Quote() + "static" + Quote() + " mediaPresentationDuration=" + Quote() + "PT"
    MPDString = MPDString + duration
    MPDString = MPDString + "S" + Quote() + ">"
    MPDString = MPDString + "<Period duration=" + Quote() + "PT" + duration + "S" + Quote() + ">"
    ' Audio
    firstSDecrypt = true
    retObj = {}
    retObj.didFail = false
    retObj.mpdString = invalid
    if ( formatData[ "140" ] <> invalid ) then
        audioData = formatData["140"]
        if (audioData.s = invalid) then
            encodedURL = audioData.url.DecodeUri().DecodeUri().GetEntityEncode()
        else
            youtube.UpdateWaitDialog( "Decoding signature...", "Creating DASH Manifest" )
            signatureValObj = decodeEncryptedS( videoID, firstSDecrypt, URLDecode( URLDecode( audioData.s ) ) )
            firstSDecrypt = false
            if ( signatureValObj.didFail = true ) then
                youtube.waitDialog.Close()
                youtube.waitDialog = invalid
                return signatureValObj
            else
                spField = "signature"
                if ( audioData["sp"] <> invalid ) then
                    spField = audioData.sp
                end if
                encodedURL = audioData.url.DecodeUri().DecodeUri().GetEntityEncode() + "&amp;" + spField + "=" + signatureValObj.signature
            end if
        end if
        if ( youtube.DEBUG ) then
            print "Audio Encoded URL is: " + encodedURL
        end if
        MPDString = MPDString + "<AdaptationSet id=" + Quote() + "0" + Quote() + " mimeType=" + Quote() + "audio/mp4" + Quote() + " subsegmentAlignment=" + Quote() + "true" + Quote() + ">"
        MPDString = MPDString + "<Role schemeIdUri=" + Quote() + "urn:mpeg:DASH:role:2011" + Quote() + " value=" + Quote() + "main" + Quote() + "/>"
        MPDString = MPDString + "<Representation id=" + Quote() + "140" + Quote() + " codecs=" + Quote() + "mp4a.40.2" + Quote() + " audioSamplingRate=" + Quote() + "44100" + Quote() + " startWithSAP=" + Quote() + "1" + Quote() + " bandwidth=" + Quote() + toStr( Int( audioData.bitrate.ToInt() / 8 ) ).Trim() + Quote() + ">"
        MPDString = MPDString + "<AudioChannelConfiguration schemeIdUri=" + Quote() + "urn:mpeg:dash:23003:3:audio_channel_configuration:2011" + Quote() + " value=" + Quote() + "2" + Quote() + "/>"
        MPDString = MPDString + "<BaseURL yt:contentLength=" + Quote() + toStr( Int( audioData.clen.ToInt() / 8 ) ).Trim() + Quote() + ">" + encodedURL + "</BaseURL>"
        MPDString = MPDString + "<SegmentBase indexRange=" + Quote() + audioData.index + Quote() + " indexRangeExact=" + Quote() + "true" + Quote() + ">"
        MPDString = MPDString + "<Initialization range=" + Quote() + audioData.init + Quote() + "/>"
        MPDString = MPDString + "</SegmentBase></Representation></AdaptationSet>"
        setID = 1
        if ( getYoutube().audio_only = false ) then
            for each formatKey in formatData
                format = formatData[ formatKey ]
                if ( format["type"] <> invalid AND format.type.InStr( "audio" ) = -1 AND validateDASHVideoFields( format ) ) then
                    if ( format.itag.ToInt() < 210 ) then
                        ' Check for encoded signature
                        if (format["s"] = invalid) then
                            videoURL = format.url.DecodeUri().DecodeUri().GetEntityEncode()
                        else
                            youtube.UpdateWaitDialog( "Decoding next video URL" )
                            'print "s: " ; format.s
                            'print "s: " ;  URLDecode( URLDecode( format.s ) )
                            signatureValObj = decodeEncryptedS( videoID, firstSDecrypt, URLDecode( URLDecode( format.s ) ) )
                            firstSDecrypt = false
                            if ( signatureValObj.didFail = true ) then
                                youtube.waitDialog.Close()
                                youtube.waitDialog = invalid
                                return signatureValObj
                            else
                                spField = "signature"
                                if ( format["sp"] <> invalid ) then
                                    spField = format.sp
                                end if
                                videoURL = format.url.DecodeUri().DecodeUri().GetEntityEncode() + "&amp;" + spField + "=" + signatureValObj.signature
                            end if
                        end if
                        'print "Video Encoded URL is: " + videoURL
                        formatTypeEscaped = format.type.Unescape().Unescape()
                        codecStr = getRegexes().codecRegex.Match( formatTypeEscaped )[1]
                        lenStr = toStr( Int( format.clen.ToInt() / 8 ) ).Trim()
                        if ( format["size"] <> invalid ) then
                            resolutionSplit = format.size.Split( "x" )
                            widthStr = resolutionSplit[0]
                            heightStr = resolutionSplit[1]
                        else
                            widthStr = format.width
                            heightStr = format.height
                        end if
                        bandwidthStr = toStr( Int( format.bitrate.ToInt() / 8 ) ).Trim()
                        MPDString = MPDString + "<AdaptationSet id=" + Quote() + toStr( setID ) + Quote() + " mimeType=" + Quote() + formatTypeEscaped.split( ";" )[0] + Quote() + " subsegmentAlignment=" + Quote() + "true" + Quote() + ">"
                        MPDString = MPDString + "<Role schemeIdUri=" + Quote() + "urn:mpeg:DASH:role:2011" + Quote() + " value=" + Quote() + "main" + Quote() + "/>"
                        MPDString = MPDString + "<Representation id=" + Quote() + format.itag + Quote() + " codecs=" + Quote() + codecStr + Quote() + " width=" + Quote() + widthStr + Quote() + " height=" + Quote() + heightStr + Quote() + " startWithSAP=" + Quote() + "1" + Quote() + " maxPlayoutRate=" + Quote() + "1" + Quote() + " bandwidth=" + Quote() + bandwidthStr + Quote() + " frameRate=" + Quote() + format.fps + Quote() + ">"
                        MPDString = MPDString + "<BaseURL yt:contentLength=" + Quote() + lenStr + Quote() + ">" + videoURL + "</BaseURL>"
                        MPDString = MPDString + "<SegmentBase indexRange=" + Quote() + format.index + Quote() + " indexRangeExact=" + Quote() + "true" + Quote() + ">"
                        MPDString = MPDString + "<Initialization range=" + Quote() + format.init + Quote() + "/>"
                        MPDString = MPDString + "</SegmentBase></Representation></AdaptationSet>"
                        setID = setID + 1
                    end if
                end if
            end for
        end if
        MPDString = MPDString + "</Period></MPD>"
        if ( youtube.DEBUG ) then
            print MPDString
        end if

        if ( setID = 1 AND getYoutube().audio_only = false ) then
            print "No video streams found?"
            retObj.didFail = true
            retObj.mpdString = invalid
        else
            retObj.mpdString = MPDString
        end if
    else
        print "No audio data found!"
        retObj.didFail = true
        retObj.mpdString = invalid
    end if
    if ( youtube.waitDialog <> invalid ) then
        youtube.waitDialog.Close()
        youtube.waitDialog = invalid
    end if
    return retObj
End Function

Function validateDASHVideoFields( formatData as Object ) as Boolean
    retVal = false
    if ( formatData["itag"] <> invalid AND formatData["clen"] <> invalid AND formatData["bitrate"] <> invalid AND formatData["fps"] <> invalid AND formatData["index"] <> invalid AND formatData["init"] <> invalid ) then
        retVal = true
    else
        if ( getYoutube().DEBUG ) then
            PrintAny(0, "Invalid DASH Video Format Data:", formatData)
        end if
    end if
    return retVal
End Function

Function decodeEncryptedS( videoID as String, first as Boolean, sVal as String )
    youtube = getYoutube()
    getJSUrl = first
    retObj = {}
    retObj.didFail = false
    retObj.stsValChanged = false
    retObj.signature = invalid
    if ( sVal <> invalid AND sVal <> "" ) then
        ' Use this to just quit early since DASH doesn't work with the encoded URLs for some reason
        'return getYouTubeMP4Url( video, false, 0 )
        if ( getJSUrl = true ) then
            youtube.UpdateWaitDialog( "Downloading webpage..." )
            functionMap = get_js_sm( videoID )
            getJSUrl = false
        else
            functionMap = getYoutube().funcmap
        end if
        if ( functionMap <> invalid AND functionMap["stsValChanged"] = invalid ) then
            getYoutube().funcmap = functionMap
            youtube.UpdateWaitDialog( "Decoding signature..." )
            newSig = decodesig( sVal )
            if ( newSig <> invalid ) then
                'signature = "/signature/" + newSig
                retObj.signature = newSig
                youtube.UpdateWaitDialog( "Done!" )
            else
                retObj.didFail = true
                print "Failed to decode signature!"
                youtube.UpdateWaitDialog( "Failed to decode signature!" )
            end if
        else if ( functionMap <> invalid AND functionMap["stsValChanged"] <> invalid ) then
            functionMap["stsValChanged"] = invalid
            getYoutube().funcmap = functionMap
            retObj.didFail = true
            print "STS value has changed :: decodeEncryptedS"
            retObj.stsValChanged = true
            youtube.UpdateWaitDialog( "STS value has changed, going to retry." )
        else ' functionMap = invalid
            retObj.didFail = true
            print "Failed to parse javascript!"
            youtube.UpdateWaitDialog( "Failed to parse javascript!" )
        end if
    end if
    return retObj
End Function

Function createDASHManifest( videoID, htmlString )
    youtube = getYoutube()
    manifestObj = {}
    ' Default to true in case something in this function fails
    manifestObj.didFail = true
    durRegex = CreateObject("roRegex", "dur(?:%3D|%253D)([\d\.]+)", "ig")
    regexes = getRegexes()
    urlEncodedRegex = CreateObject("roRegex", "%22adaptiveFormats%22%3A%5B%7B(.*?)%7D%5D%2C", "ig")
    durMatch = durRegex.Match( htmlString )
    durationFromInfo = invalid
    if ( durMatch.Count() > 1 ) then
        maxDur = 0.0
        durValues = MatchAll( durRegex, htmlString )
        for each durVal in durValues
            if ( durVal.ToFloat() > maxDur ) then
                maxDur = durVal.ToFloat()
                durationFromInfo = durVal
                print "Set duration to: " + durationFromInfo
            end if
        end for
        if ( durationFromInfo <> invalid ) then
            adaptiveFmtsStringMatch = urlEncodedRegex.Match( htmlString )
            if ( adaptiveFmtsStringMatch.Count() > 1 ) then
                getYoutube().UpdateWaitDialog( "Found DASH info, parsing..." )
                formatData = {}
                if (not(strTrim(adaptiveFmtsStringMatch[1]) = "")) then
                    adaptiveFmtsString = adaptiveFmtsStringMatch[1]
                    commaSplit = regexes.commaRegexHex.Split( adaptiveFmtsString )
                    ' Result is now in JSON format, not a URL encoded format
                    ' Parse it in a pretty gross way
                    itag = invalid
                    settings = invalid
                    rangeStart = invalid
                    whichRange = invalid
                    if ( youtube.DEBUG ) then
                        print "##############"
                    end if
                    for each commaItem in commaSplit
                        colonSplit = regexes.colonRegexHex.split( commaItem )
                        if ( youtube.DEBUG ) then
                            print "commaItem: " + commaItem
                        end if
                        key = regexes.quoteRegexHex.ReplaceAll(colonSplit[0], Quote())
                        quotedValue = regexes.quotedValueRegex.Match( key )
                        ' Some things get parsed weird since it's not parsing JSON, but rather doing string matching
                        if ( quotedValue.Count() > 1 AND colonSplit.Count() > 1 ) then
                            key = quotedValue[1]
                            fullRightSide = colonSplit[1]
                            if (colonSplit.Count() > 2) then
                                for i = 2 to colonSplit.Count() - 1  Step +1
                                    fullRightSide = fullRightSide + ":" + colonSplit[i]
                                end for
                            end if
                            value = htmlDecodeFromYouTube( removeEncodedJSONCharactersFromYouTube( fullRightSide ) )
                            if ( key = "itag" and itag = invalid ) then
                                itag = value
                                settings = {}
                            else if ( key = "itag" ) then
                                formatData[ itag ] = settings
                                if ( youtube.DEBUG ) then
                                    print "Storing settings for itag value: " ; itag
                                    print "##############"
                                end if
                                itag = value
                                settings = {}
                            end if
                            ' Need to handle range information for the MPD Segment information
                            if ( key = "initRange" ) then
                                whichRange = "init"
                                rangeStart = strReplace( value, "start:", "" )
                            else if ( key = "indexRange" ) then
                                rangeStart = strReplace( value, "start:", "" )
                                whichRange = "index"
                            else if ( key = "end" AND whichRange <> invalid ) then
                                settings[ whichRange ] = rangeStart + "-" + value
                                if ( youtube.DEBUG ) then
                                    print "Setting range info: " ; whichRange ; "=" ; rangeStart + "-" + value
                                end if
                                whichRange = invalid
                                rangeStart = invalid
                            else if ( key = "contentLength" ) then
                                settings[ "clen" ] = value
                                if ( youtube.DEBUG ) then
                                    print "Setting clen to: " ; value
                                end if
                            else if ( key = "mimeType" ) then
                                settings[ "type" ] = value
                                if ( youtube.DEBUG ) then
                                    print "Setting type to: " ; value
                                end if
                            else if ( key = "cipher" ) then
                                if ( youtube.DEBUG ) then
                                    print "Cipher values: " ; key ; "=" ; value
                                end if
                                ampersandSplit = regexes.ampersandRegex.Split( value )
                                for each ampersandItem in ampersandSplit
                                    if ( youtube.DEBUG ) then
                                        print("ampersandItem: " + ampersandItem)
                                    end if
                                    equalsSplit = regexes.equalsRegex.Split( ampersandItem )
                                    if (equalsSplit.Count() = 2) then
                                        'pair[equalsSplit [0]] = equalsSplit [1]
                                        'if ( equalsSplit[0] = "s" OR equalsSplit[0] = "sp" ) then
                                        settings[ equalsSplit[0] ] = equalsSplit[1]
                                        'end if
                                    end if
                                end for
                                settings[key] = value
                            else
                                if ( youtube.DEBUG ) then
                                    print key ; "=" ; value
                                end if
                                settings[key] = value
                            end if
                        end if
                    end for
                    if ( itag <> invalid AND settings <> invalid ) then
                        formatData[ itag ] = settings
                        if ( youtube.DEBUG ) then
                            print "Finally storing settings for itag value: " ; itag
                        end if
                    end if
                    if ( youtube.DEBUG ) then
                        print "##############"
                    end if
                    manifestObj = dashManifest( videoID, formatData, durationFromInfo )
                else
                    print "Empty adaptiveFmtsString"
                end if
            else
                print "Adaptive formats regex failed"
            end if
        else
            print "Failed to find valid duration!"
        end if
    else
        print "Duration regex failed"
    end if
    return manifestObj
End Function

Function getYouTubeDASHMPD( htmlString as String, video as Object, isSSL as Boolean )
    htmlString = firstValid( htmlString, "" )

    ' When true, tells the calling function to retry, since the STS value has changed
    stsValChanged = false
    manifestObj = invalid
    if ( len( htmlString ) > 0 ) then
        getYoutube().dashManifestContents = invalid
        manifestObj = createDASHManifest( video["ID"], htmlString )

        if ( manifestObj <> invalid ) then
            if ( manifestObj.didFail = false ) then
                getYoutube().dashManifestContents = manifestObj.mpdString
                streamData = {url: "http://localhost:6789", bitrate: 3000, quality: true, contentid: "dash" }
                video["Streams"].Push( streamData )

                if (video["Streams"].Count() > 0) then
                    video["Live"]          = false
                    video["StreamFormat"]  = "dash"
                    video["HDBranded"]     = true
                    video["IsHD"]          = true
                    video["FullHD"]        = true
                    video["SSL"]           = true
                    video["TrackIDAudio"]  = "140"
                end if
            end if
        end if
    end if
    if ( manifestObj <> invalid AND (manifestObj.stsValChanged = invalid OR manifestObj.staValChanged = false ) ) then
        ' If the STS value hasn't changed, return the array, even if it's empty.
        return video["Streams"]
    else
        ' If the STS value has changed, return invalid
        print "Detected STS value change, returning invalid in getYouTubeDASHMPD"
        return invalid
    end if
End Function

Function getYouTubeOrGDriveURLs( htmlString as String, video as Object, isSSL as Boolean, retryCount as Integer )
    youtube = getYoutube()
    urlEncodedRegex = CreateObject("roRegex", "url_encoded_fmt_stream_map=([^(" + Chr(34) + "|&|$)]*)", "ig")
    regexes = GetRegexes()
    commaRegex = regexes.commaRegexHex
    ampersandRegex = regexes.ampersandRegexHex
    equalsRegex = regexes.equalsRegexHex

    if ( video["Source"] = getConstants().sGOOGLE_DRIVE ) then
        urlEncodedRegex = CreateObject( "roRegex", Chr(34) + "url_encoded_fmt_stream_map" + Chr(34) + "[\:,]" + Chr(34) + "([^(" + Chr(34) + "|&|$)]*)" + Chr(34), "ig" )
        commaRegex = regexes.commaRegex
        ampersandRegex = regexes.ampersandRegexUnicode
        equalsRegex = regexes.equalsRegexUnicode
    end if
    htmlString = firstValid( htmlString, "" )
    urlEncodedFmtStreamMap = urlEncodedRegex.Match( htmlString )

    constants = getConstants()
    prefs = getPrefs()
    videoQualityPref = prefs.getPrefValue( constants.pVIDEO_QUALITY )
    getJSUrl = true
    didFail = false
    ' When true, tells the calling function to retry, since the STS value has changed
    stsValChanged = false
    pleaseWaitDlg = invalid
    if (urlEncodedFmtStreamMap.Count() > 1) then
        if (not(strTrim(urlEncodedFmtStreamMap[1]) = "")) then
            commaSplit = commaRegex.Split( urlEncodedFmtStreamMap[1] )
            hasHD = false
            fullHD = false
            topQuality% = -1
            if ( videoQualityPref = constants.FORCE_LOWEST ) then
                topQuality% = 10000
            end if
            streamData = invalid
            for each commaItem in commaSplit
                if ( youtube.DEBUG ) then
                    print("CommaItem: " + commaItem)
                end if
                pair = {itag: "", url: "", sig: ""}
                ampersandSplit = ampersandRegex.Split( commaItem )
                for each ampersandItem in ampersandSplit
                    if ( youtube.DEBUG ) then
                        print("ampersandItem: " + ampersandItem)
                    end if
                    equalsSplit = equalsRegex.Split( ampersandItem )
                    if (equalsSplit.Count() = 2) then
                        pair[equalsSplit [0]] = equalsSplit [1]
                    end if
                end for
                ' printAA( pair )
                if (pair.url <> "" and Left(LCase(pair.url), 4) = "http") then
                    signature = ""
                    if ( pair.s <> invalid AND pair.s <> "" ) then
                        if ( getJSUrl = true ) then
                            youtube.UpdateWaitDialog( "Downloading webpage...", "Decoding signature" )
                            functionMap = get_js_sm( video["ID"] )
                            getJSUrl = false
                        else
                            functionMap = youtube.funcmap
                        end if
                        if ( functionMap <> invalid AND functionMap["stsValChanged"] = invalid ) then
                            youtube.funcmap = functionMap
                            youtube.UpdateWaitDialog( "Decoding signature..." )
                            newSig = decodesig( pair.s )
                            if ( newSig <> invalid ) then
                                spField = "signature"
                                if ( pair["sp"] <> invalid ) then
                                    spField = pair.sp
                                end if

                                signature = "&" + spField + "=" + newSig
                                youtube.UpdateWaitDialog( "Done!" )
                            else
                                didFail = true
                                print "Failed to decode signature!"
                                youtube.UpdateWaitDialog( "Failed to decode signature!" )
                            end if
                        else if ( functionMap <> invalid AND functionMap["stsValChanged"] <> invalid ) then
                            functionMap["stsValChanged"] = invalid
                            youtube.funcmap = functionMap
                            didFail = true
                            print "STS value has changed"
                            stsValChanged = true
                            youtube.UpdateWaitDialog( "STS value has changed, going to retry." )
                        else ' functionMap = invalid
                            didFail = true
                            print "Failed to parse javascript!"
                            youtube.UpdateWaitDialog( "Failed to parse javascript!" )
                        end if
                    else
                        if (pair.sig <> "") then
                            signature = "&signature=" + pair.sig
                        else
                            signature = ""
                        end if
                    end if
                    if ( didFail = false ) then
                        urlDecoded = URLDecode(URLDecode(pair.url + signature))
                        itag% = strtoi( pair.itag )
                        if ( itag% <> invalid AND ( itag% = 18 OR itag% = 22 ) ) then
                            if ( Left( LCase( urlDecoded ), 5) = "https" ) then
                                isSSL = true
                            else if ( isSSL <> true )
                                isSSL = false
                            end if
                            'printAA( pair )
                            ' Determined from here: http://en.wikipedia.org/wiki/YouTube#Quality_and_codecs
                            if ( videoQualityPref = constants.NO_PREFERENCE ) then
                                if ( itag% = 18 ) then
                                    ' 18 is MP4 270p/360p H.264 at .5 Mbps video bitrate
                                    video["Streams"].Push( {url: urlDecoded, bitrate: 512, quality: false, contentid: pair.itag} )
                                'else if ( itag% = 22 ) then
                                '    ' The Roku platform fails to decode this video.
                                '    ' 22 is MP4 720p H.264 at 2-2.9 Mbps video bitrate. I set the bitrate to the maximum, for best results.
                                '    video["Streams"].Push( {url: urlDecoded, bitrate: 2969, quality: true, contentid: pair.itag} )
                                '    hasHD = true
                                end if
                            else if ( ( videoQualityPref = constants.FORCE_HIGHEST AND itag% > topQuality% ) OR ( videoQualityPref = constants.FORCE_LOWEST AND itag% < topQuality% ) ) then
                                if ( itag% = 18 ) then
                                    ' 18 is MP4 270p/360p H.264 at .5 Mbps video bitrate
                                    streamData = {url: urlDecoded, bitrate: 512, quality: false, contentid: pair.itag}
                                    topQuality% = itag%
                                'else if ( itag% = 22 ) then
                                '    ' The Roku platform fails to decode this video.
                                '    ' 22 is MP4 720p H.264 at 2-2.9 Mbps video bitrate. I set the bitrate to the maximum, for best results.
                                '    streamData = {url: urlDecoded, bitrate: 2969, quality: true, contentid: pair.itag}
                                '    hasHD = true
                                '    topQuality% = itag%
                                end if
                            end if
                        'else
                        '    print "Tried to parse invalid itag value: " ; tostr ( itag% )
                        end if
                    end if
                end if
            end for
            if ( didFail = false ) then
                if ( streamData <> invalid ) then
                    video["Streams"].Push( streamData )
                end if
                if (video["Streams"].Count() > 0) then
                    video["Live"]          = false
                    video["StreamFormat"]  = "mp4"
                    video["HDBranded"] = hasHD
                    video["IsHD"] = hasHD
                    video["FullHD"] = fullHD
                    video["SSL"] = isSSL
                end if
            end if
        else
            'hlsUrl = CreateObject("roRegex", "hlsvp=([^(" + Chr(34) + "|&|$)]*)", "").Match(htmlString)
            ' htmlString is encoded still at this point
            ' new raw (Jan 2019): "hlsManifestUrl.+?(https?%3A.+?)%22
            hlsUrl = CreateObject("roRegex", "hlsManifestUrl.+?(https?%3A.+?)%22", "i").Match(htmlString)
            if (hlsUrl.Count() > 1) then
                urlDecoded = URLDecode(URLDecode(URLDecode(hlsUrl[1])))
                'print "raw: " ; hlsUrl[1]
                'print "urlDecoded: " ; urlDecoded
                if ( Left( LCase( urlDecoded ), 5) = "https" ) then
                    isSSL = true
                else if ( isSSL <> true )
                    isSSL = false
                end if
                video["Streams"].Clear()
                video["Live"]              = true
                ' Set the PlayStart sufficiently large so it starts at 'Live' position
                video["PlayStart"]        = 500000
                video["StreamFormat"]      = "hls"
                'video["SwitchingStrategy"] = "unaligned-segments"
                video["SwitchingStrategy"] = "full-adaptation"
                'print ("HLS URL: " + urlDecoded)
                video["MaxBandwidth"] = firstValid( getEnumValueForType( constants.eHLS_MAX_BANDWIDTH, prefs.getPrefValue( constants.pHLS_MAX_BANDWIDTH ) ), "0" ).ToInt()
                video["Streams"].Push({url: urlDecoded, bitrate: 0, quality: false, contentid: -1})
                video["SSL"] = isSSL
            else
                print "Failed to extract Live Stream URL"
            end if

        end if
    else
        if ( retryCount < 1 ) then
            print ( "Nothing in urlEncodedFmtStreamMap, retrying with different URL." )
            if (pleaseWaitDlg <> invalid) then
                pleaseWaitDlg.Close()
            end if
            return getYouTubeMP4Url(video, false, 1)
        else
            print ( "Retries exceeded, giving up!" )
        end if
    end if
    if (pleaseWaitDlg <> invalid) then
        pleaseWaitDlg.Close()
    end if
    if ( stsValChanged = false ) then
        return video["Streams"]
    else
        return invalid
    end if
End Function

Sub getGDriveFolderContents(video as Object, timeout = 0 as Integer, loginCookie = "" as String)
    screen = uitkPreShowPosterMenu( "flat-episodic-16x9", firstValid( video["TitleSeason"], "GDrive Playlist" ) )
    screen.showMessage( "Loading Google Drive Folder Contents" )
    videos = []
    if ( video["URL"] <> invalid ) then
        gdriveFolderRegex1 = CreateObject( "roRegex", "viewerItems: \[(\[.*\]\n)\]", "igs" )
        url = video["URL"]
        isSSL = false
        if ( Left( LCase( url ), 5) = "https" ) then
            isSSL = true
        end if

        port = CreateObject( "roMessagePort" )
        ut = CreateObject( "roUrlTransfer" )
        ut.SetPort( port )
        ut.AddHeader( "User-Agent", getConstants().USER_AGENT )
        ut.AddHeader( "Cookie", loginCookie )
        ut.SetUrl( url )
        if ( isSSL = true ) then
            ut.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
            ' Wrap in an eval() block to catch any potential errors.
            eval( "ut.SetCertificatesDepth( 3 )" )
            ut.InitClientCertificates()
        end if
        if ( ut.AsyncGetToString() ) then
            while ( true )
                msg = Wait( timeout, port )
                if ( type(msg) = "roUrlEvent" ) then
                    status = msg.GetResponseCode()
                    if ( status = 200 ) then
                        responseString = msg.GetString()
                        matches = gdriveFolderRegex1.Match( responseString )
                        if ( matches <> invalid AND matches.Count() > 1 ) then
                            vidList = matches[1]
                            itemRegex = CreateObject( "roRegex", "\]\n+,", "igs" )
                            splitUp = itemRegex.Split( vidList )
                            ' print "Split gave " ; tostr( splitUp.Count() ) ; " items"
                            titleRegex = CreateObject( "roRegex", "\[,," + Quote() + "(.*)" + Quote() + ",(" + Quote() + "http|,,,,)", "ig" )
                            urlRegex = CreateObject( "roRegex", "\d+," + Quote() + "(http.*edit)", "ig" )
                            mimeTypeRegex = CreateObject( "roRegex", "\,\,\," + Quote() + "video\/.*?" + Quote() + "\,\,\,", "ig" )
                            if ( splitUp <> invalid ) then
                                for each split in splitUp
                                    'print split
                                    if ( mimeTypeRegex.isMatch( split ) ) then
                                        vidUrlMatch = urlRegex.Match( split )
                                        if ( vidUrlMatch.Count() > 1 ) then
                                            titleMatch = titleRegex.Match( split )
                                            if ( titleMatch.Count() > 1 ) then
                                                videos.Push( NewGDriveFolderVideo( titleMatch[1], vidUrlMatch[1] ) )
                                            else
                                                videos.Push( NewGDriveFolderVideo( "Failed title parse", vidUrlMatch[1] ) )
                                                print "Failed to match video title for string: " ; tostr( split )
                                            end if
                                        else
                                            print "Failed to find video URL in string: " ; tostr( split )
                                        end if
                                    end if
                                next
                            end if
                        end if
                    end if
                    exit while
                else if ( type(msg) = "Invalid" ) then
                    ut.AsyncCancel()
                    exit while
                end if
            end while
        end if
    end if
    if ( videos.Count() > 0 ) then
        m.youtube.DisplayVideoListFromVideoList( videos, video["TitleSeason"], invalid, screen, invalid, GetRedditMetaData )
    else
        ShowDialog1Button( "Warning", "This folder appears to not have any compatible videos.", "Got it" )
    end if
end sub

'******************************************************************************
' Creates a video roAssociativeArray, with the appropriate members needed to set Content Metadata and play a video with
' This is a special version for Google Drive folder items. The information available for these videos is extremely limited.
' @param title  The title of the video
' @param url    The URL for the video
' @return an roAssociativeArray of metadata for the current result
'******************************************************************************
Function NewGDriveFolderVideo(title as String, url as String) As Object
    video               = {}
    ' The URL needs to be decoded prior to attempting to match
    decodedUrl = URLDecode( htmlDecode( url ) )
    yt = getYoutube()
    constants = getConstants()
    video["URL"] = url

    id = url

    regexFolderView = CreateObject( "roRegex", ".*folderview.*", "i" )
    if ( regexFolderView.IsMatch( url ) = true ) then
        video["isPlaylist"] = true
        video["URL"] = id
    end if

    video["Source"]        = constants.sGOOGLE_DRIVE
    video["ID"]            = id
    video["Title"]         = Left( htmlDecode( title ), 100)

    video["Description"]   = ""
    video["Thumb"]         = getDefaultThumb( "", constants.sGOOGLE_DRIVE )
    return video
End Function

Function getGfycatMP4Url(video as Object, timeout = 0 as Integer, loginCookie = "" as String) as Object
    video["Streams"].Clear()

    if ( video["ID"] <> invalid ) then
        url = "https://gfycat.com/cajax/get/" + video["ID"]
        jsonString = ""
        port = CreateObject( "roMessagePort" )
        ut = CreateObject( "roUrlTransfer" )
        ut.SetPort( port )
        ut.AddHeader( "User-Agent", getConstants().USER_AGENT )
        ut.AddHeader( "Cookie", loginCookie )
        ut.SetUrl( url )
        ut.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
        ' Wrap in an eval() block to catch any potential errors.
        eval( "ut.SetCertificatesDepth( 3 )" )
        ut.InitClientCertificates()
        if ( ut.AsyncGetToString() ) then
            while ( true )
                msg = Wait( timeout, port )
                if ( type(msg) = "roUrlEvent" ) then
                    status = msg.GetResponseCode()
                    if ( status = 200 ) then
                        jsonString = msg.GetString()
                        json = ParseJson( jsonString )
                        if (json <> invalid) then
                            video["Streams"].Push( {url: htmlDecode( json.gfyItem.mp4Url ), bitrate: 512, quality: false, contentid: video["ID"]} )
                            video["Live"]          = false
                            video["StreamFormat"]  = "mp4"
                        end if
                    else
                        print( "Failed to get gfycat JSON with response: " + tostr( status ))
                    end if
                    exit while
                else if ( type(msg) = "Invalid" ) then
                    ut.AsyncCancel()
                    exit while
                end if
            end while
        else
            print( "getGfycatMP4Url AsyncGetToString() returned false" )
        end if
    else
        print( "getGfycatMP4Url video[ID] is invalid" )
    end if
    return video["Streams"]
end function

Function getLiveleakMP4Url(video as Object, timeout = 0 as Integer, loginCookie = "" as String) as Object
    video["Streams"].Clear()

    if ( video["URL"] <> invalid ) then
        liveleakMP4UrlRegex = CreateObject( "roRegex", "source\s+src=\" + Quote() + "(.*)\" + Quote() + "[^>]*label=\" + Quote() + "(SD|360p)\" + Quote() , "ig" )
        liveleakMP4HDUrlRegex = CreateObject( "roRegex", "source\s+src=\" + Quote() + "(.*)\" + Quote() + "[^>]*label=\" + Quote() + "HD\" + Quote(), "ig" )

        url = video["URL"]
        port = CreateObject( "roMessagePort" )
        ut = CreateObject( "roUrlTransfer" )
        if ( Left( LCase( url ), 5 ) <> "https" ) then
            httpToHttpsRegex = CreateObject( "roRegex", "http", "ig" )
            url = httpToHttpsRegex.replace( url, "https" )
        end if
        ut.SetPort( port )
        ut.AddHeader( "User-Agent", getConstants().USER_AGENT )
        ut.AddHeader( "Cookie", loginCookie )
        ut.SetUrl( url )
        ut.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
        ' Wrap in an eval() block to catch any potential errors.
        eval( "ut.SetCertificatesDepth( 3 )" )
        ut.InitClientCertificates()
        if ( ut.AsyncGetToString() ) then
            while ( true )
                msg = Wait( timeout, port )
                if ( type(msg) = "roUrlEvent" ) then
                    status = msg.GetResponseCode()
                    if ( status = 200 ) then
                        print "Getting Liveleak URL: " + url + " returned 200."
                        responseString = msg.GetString()
                        matches = liveleakMP4UrlRegex.Match( responseString )
                        if ( matches <> invalid AND matches.Count() > 1 ) then
                            video["Streams"].Push( {url: URLDecode( htmlDecode( matches[1] ) ), bitrate: 512, quality: false, contentid: video["ID"]} )
                            video["Live"]          = false
                            video["StreamFormat"]  = "mp4"
                        else
                            print "Failed to match liveleak SD regex"
                        end if

                        hdmatches = liveleakMP4HDUrlRegex.Match( responseString )
                        if ( hdmatches <> invalid AND hdmatches.Count() > 1 ) then
                            video["Streams"].Push( {url: URLDecode( htmlDecode( hdmatches[1] ) ), bitrate: 2969, quality: true, contentid: video["ID"]} )
                            video["Live"]          = false
                            video["StreamFormat"]  = "mp4"
                            video["HDBranded"] = true
                            video["IsHD"] = true
                        else
                            print "Failed to match liveleak HD regex"
                        end if
                    else
                        print "ERROR: Getting Liveleak URL: " + url + " returned " + tostr( status )
                    end if
                    exit while
                else if ( type(msg) = "Invalid" ) then
                    ut.AsyncCancel()
                    exit while
                end if
            end while
        end if
    end if
    return video["Streams"]
end function

Function getVidziMP4Url(video as Object) as Object
    video["Streams"].Clear()

    if ( video["URL"] <> invalid ) then
        vidziMP4UrlRegex = CreateObject( "roRegex", "file:.*?" + Quote() + "(.*?\.mp4)" + Quote(), "i" )
        url = video["URL"]
        http = NewHttp( url )
        headers = { }
        headers["User-Agent"] = getConstants().USER_AGENT
        htmlString = firstValid( http.getToStringWithTimeout(10, headers), "" )
        matches = vidziMP4UrlRegex.Match( htmlString )
        if ( matches <> invalid AND matches.Count() > 1 ) then
            video["Streams"].Push( {url: URLDecode( htmlDecode( matches[1] ) ), bitrate: 0, quality: false, contentid: url} )
            video["Live"]          = false
            video["StreamFormat"]  = "mp4"
        end if
    end if

    return video["Streams"]
end function

Function getStreamableMP4Url(video as Object) as Object
    video["Streams"].Clear()

    if ( video["URL"] <> invalid ) then
        streamableMP4UrlRegex = CreateObject( "roRegex", "og:video:url.*content=\" + Quote() + "(.*)\" + Quote(), "i" )
        url = video["URL"]
        http = NewHttp( url )
        headers = { }
        headers["User-Agent"] = getConstants().USER_AGENT
        htmlString = firstValid( http.getToStringWithTimeout(10, headers), "" )
        matches = streamableMP4UrlRegex.Match( htmlString )
        if ( matches <> invalid AND matches.Count() > 1 ) then
            video["Streams"].Push( {url: htmlDecode( matches[1] ), bitrate: 0, quality: false, contentid: url} )
            video["Live"]          = false
            video["StreamFormat"]  = "mp4"
        end if
    end if

    return video["Streams"]
end function

Function getVineMP4Url(video as Object, timeout = 0 as Integer, loginCookie = "" as String) as Object
    video["Streams"].Clear()

    if ( video["URL"] <> invalid ) then
        vineIDRegex = CreateObject( "roRegex", "https?://(?:www\.)?vine\.co/(?:v|oembed)/(\w+)", "ig" )
        url = video["URL"]
        idMatches = vineIDRegex.match( url )
        videoID = invalid
        if ( idMatches <> invalid AND idMatches.Count() > 1) then
            videoID = idMatches[1]
        else
            print "Failed to find Vine video ID from URL " + url
            return invalid
        end if
        isSSL = false
        url = "https://archive.vine.co/posts/" + videoID + ".json"
        if ( Left( LCase( url ), 5 ) = "https" ) then
            isSSL = true
        end if
        port = CreateObject( "roMessagePort" )
        ut = CreateObject( "roUrlTransfer" )
        ut.SetPort( port )
        ut.AddHeader( "User-Agent", getConstants().USER_AGENT )
        ut.AddHeader( "Cookie", loginCookie )
        if ( isSSL = true ) then
            ut.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
            ' Wrap in an eval() block to catch any potential errors.
            eval( "ut.SetCertificatesDepth( 3 )" )
            ut.InitClientCertificates()
        end if
        ut.SetUrl( url )
        if ( ut.AsyncGetToString() ) then
            while ( true )
                msg = Wait( timeout, port )
                if ( type(msg) = "roUrlEvent" ) then
                    status = msg.GetResponseCode()
                    if ( status = 200 ) then
                        responseString = msg.GetString()
                        jsonObj = ParseJson( responseString )

                        if ( jsonObj <> invalid AND jsonObj.videoUrl <> invalid ) then
                            video["Streams"].Push( {url: URLDecode( jsonObj.videoUrl ), bitrate: 512, quality: false, contentid: video["ID"]} )
                            video["Live"]          = false
                            video["StreamFormat"]  = "mp4"
                            if ( Left( LCase( jsonObj.videoUrl ), 5 ) = "https" ) then
                                video["SSL"] = true
                            else
                                video["SSL"] = false
                            end if
                        end if
                    end if
                    exit while
                else if ( type(msg) = "Invalid" ) then
                    ut.AsyncCancel()
                    exit while
                end if
            end while
        end if
    end if
    return video["Streams"]
end function

Function getImgurMP4Url(video as Object) as Object
    video["Streams"].Clear()
    if ( video["URL"] <> invalid AND video["URL"].inStr(0, ".gifv") > 0 ) then
        url = video["URL"].Replace(".gifv", ".mp4")
        video["Streams"].Push( {url: url, bitrate: 0, quality: false, contentid: url} )
        video["Live"]          = false
        video["StreamFormat"]  = "mp4"
    end if
    return video["Streams"]
end function

Function getRedditHLSUrl(video as Object) as Object
    video["Streams"].Clear()
    if ( video["URL"] <> invalid ) then
        idRegex = CreateObject("roRegex", "it\/(.*)$", "ig")
        idMatch = idRegex.Match( video["URL"] )
        if ( idMatch.Count() > 1 ) then
            url = "https://v.redd.it/" + idMatch[1] + "/HLSPlaylist.m3u8"
            video["Streams"].Push( {url: url, bitrate: 0, quality: false, contentid: url} )
            video["Live"]          = false
            video["StreamFormat"]  = "hls"
        end if
    end if
    return video["Streams"]
end function


Function video_get_qualities(video as Object) As Integer
    if ( video <> invalid AND video["Streams"] <> invalid ) then
        source = video["Source"]
        constants = getConstants()
        if ( source = invalid OR source = constants.sYOUTUBE ) then
            getYouTubeMP4Url( video )
        else if ( source = constants.sGOOGLE_DRIVE ) then
            getYouTubeMP4Url( video )
        else if ( source = constants.sGFYCAT ) then
            getGfycatMP4Url( video )
        else if ( source = constants.sLIVELEAK ) then
            getLiveleakMP4Url( video )
        else if ( source = constants.sVINE ) then
            getVineMP4Url( video )
        else if ( source = constants.sVIDZI ) then
            getVidziMP4Url( video )
        else if ( source = constants.sSTREAMABLE ) then
            getStreamableMP4Url( video )
        else if ( source = constants.sIMGUR ) then
            getImgurMP4Url( video )
        else if ( source = constants.sREDDIT ) then
            getRedditHLSUrl( video )
        end if

        if ( video["Streams"].Count() > 0 ) then
            return 0
        end if
    else
        print( "Invalid argument to video_get_qualities" )
    end if
    problem = ShowDialogNoButton( "", "Having trouble finding a Roku-compatible stream..." )
    sleep( 3000 )
    problem.Close()
    return -1
End Function

'********************************************************************
' Shows Users Video History
'********************************************************************
Sub ShowHistory_impl()
    ' Copy the history so it doesn't get updated when a video is played from this screen.
    ' Basically a 'snapshot' of the history at the time the screen was opened.
    historyCopy = []
    for each vid in m.history
        historyCopy.push( vid )
    end for
    m.DisplayVideoListFromMetadataList(historyCopy, "History", invalid, invalid, invalid)
End Sub

'********************************************************************
' Adds Video to History
' Store more data, but less items 5.
' This makes it easier to view history videos, without querying YouTube for information
' It also allows us to use the history list for the LAN Videos feature
'********************************************************************
Sub AddHistory_impl(video as Object)
    if ( firstValid( video["Live"], false ) = true ) then
        print "Not adding to history."
        return
    end if
    if ( islist(m.history) = true ) then
        ' If the item already exists in the list, move it to the front
        j = 0
        k = -1
        for each vid in m.history
            if ( vid["ID"] = video["ID"] ) then
                k = j
                exit for
            end if
            j = j + 1
        end for

        if ( k <> -1 ) then
            m.history.delete(k)
        end If

    end if

    ' Add the video to the beginning of the history list
    m.history.Unshift(video)

    'Is it safe to assume that 5 items will be less than 16KB? Need to find how to check array size in bytes in brightscript
    while(m.history.Count() > 5)
        ' Remove the last item in the list
        m.history.Pop()
    end while

    ' Don't write the streams list to the registry
    tempStreams = video["Streams"]
    video["Streams"].Clear()

    ' Make sure all the existing history items' Streams array is cleared
    ' and all of the descriptions are truncated before storing to the registry
    descs = {}
    fullDescs = {}
    for each vid in m.history
        if ( islist( vid["Streams"] ) ) then
            vid["Streams"].Clear()
        else
            vid["Streams"] = []
        end if
        descs[vid["ID"]] = vid["Description"]
        fullDescs[vid["ID"]] = vid["FullDescription"]

        if ( Len(descs[vid["ID"]]) > 50 ) then
            ' Truncate the description field for storing in the registry
            vid["Description"] = Left(descs[vid["ID"]], 50) + "..."
        end if
        vid["FullDescription"] = ""
    end for

    historyString = getRegexes().regexNewline.ReplaceAll( SimpleJSONArray(m.history), "")
    m.historyLen = Len(historyString)
    ' print("**** History string len: " + tostr(m.historyLen) + "****")
    RegWrite("videos", historyString, "history")
    video["Streams"] = tempStreams
    ' Load the non-truncated descriptions
    for each vid in m.history
        vid["Description"] = descs[vid["ID"]]
        vid["FullDescription"] = fullDescs[vid["ID"]]
    end for
End Sub

Function QueryForJson( url as String, addlHeaders = invalid as Dynamic) As Object
    rawQueryString = invalid
    querySplit = getRegexes().queryRegex.split(url)
    if ( querySplit.Count() > 1 ) then
        rawQueryString = "?" + querySplit[1]
    end if
    http = NewHttp( url, rawQueryString )
    headers = { }
    headers["User-Agent"] = getConstants().USER_AGENT
    if ( addlHeaders <> invalid ) then
        for each key in addlHeaders
            headers[key] = addlHeaders[key]
        end for
    end if
    http.method = "GET"
    rsp = http.getToStringWithTimeout( 10, headers )

    returnObj = CreateObject( "roAssociativeArray" )
    returnObj.json = ParseJson( rsp )
    if ( returnObj.json = invalid ) then
        returnObj.rsp = rsp
    else
        returnObj.rsp = returnObj.json
    end if
    returnObj.status = http.status
    return returnObj
End Function

Sub updateWaitDialogText_impl( text as String, title = "Please Wait" as String )
    if (m.waitDialog <> invalid) then
        if ( getPrefs().getPrefValue( getConstants().pROKU_ONE_SUPPORT ) = getConstants().DISABLED_VALUE )
            m.waitDialog.UpdateText( text )
        else
            ' Roku 1 doesn't support updating dialog text
            ' m.waitDialog.SetText( "Downloading javascript file..." )
        end if
    else
        m.waitDialog = ShowPleaseWait( title, text )
    end if
End Sub

Sub closeWaitDialog_impl()
    if (m.waitDialog <> invalid) then
        m.waitDialog.Close()
        m.waitDialog = invalid
    end if
End Sub
