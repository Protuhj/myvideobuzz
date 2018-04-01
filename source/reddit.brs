'******************************************************************************
' reddit.brs
' Adds support for handling reddit's json feed for subreddits
' Documentation on the API is here:
'             http://www.reddit.com/dev/api#section_listings
'******************************************************************************

'******************************************************************************
' Main function to begin displaying subreddit content
' @param youtube the current youtube instance
' @param url an optional URL with the multireddit to query, or the full link to parse. This is used when hitting the 'More Results' or 'Back' buttons on the video list page.
'     multireddits look like this: videos+funny+humor for /r/videos, /r/funny, and /r/humor
'******************************************************************************
Sub ViewReddits(youtube as Object, url = "videos" as String)
    prefs = getPrefs()
    redditQueryType = firstValid( getEnumValueForType( getConstants().eREDDIT_QUERIES, prefs.getPrefValue( prefs.RedditFeed.key ) ), "Hot" )
    redditFilterType = firstValid( getEnumValueForType( getConstants().eREDDIT_FILTERS, prefs.getPrefValue( prefs.RedditFilter.key ) ), "All" )
    title = "Reddit (" + redditQueryType
    if ( redditQueryType = "Top" or redditQueryType = "Controversial" ) then
        title = title + " - " + redditFilterType + ")"
    else
        title = title + ")"
    end if
    screen = uitkPreShowPosterMenu( "flat-episodic-16x9", title )
    screen.showMessage( "Loading subreddits..." )
    ' Added for https thumbnail support.
    screen.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
    ' Wrap in an eval() block to catch any potential errors with older firmware.
    eval( "screen.SetCertificatesDepth( 3 )" )
    screen.InitClientCertificates()
    categories = RedditCategoryList()
    if (url = "videos") then
        tempSubs = RegRead("subreddits", "reddit")
        if (tempSubs <> invalid) then
            if (Len(tempSubs) > 0) then
                url = tempSubs
            end if
        end if
    end if
    categoryList = CreateObject("roArray", 100, true)
    for each category in categories
        categoryList.Push(category.title)
    next
    ' Category selection function
     oncontent_callback = [categories, m,
        function(categories, youtube, set_idx)
            if ( categories.Count() > 0 ) then
                categories[set_idx].links.Clear()
                categories[set_idx].links.Push( categories[set_idx].link )
                metadata = doQuery( categories[set_idx].link, false, categories[set_idx] )
                return metadata
            else
                return []
            end if
        end function]
    ' Function that runs when a video/action arrow is selected
    onclick_callback = [categories, youtube,
        function(categories, youtube, video, category_idx, set_idx)
            if (video[set_idx] <> invalid) then
                if (video[set_idx]["action"] <> invalid) then
                    linksList = categories[category_idx].links

                    if (video[set_idx]["action"] = "next") then
                        ' Last item is the next item link
                        theLink = linksList.Peek()
                    else
                        ' Previous button - should only be visible if there are at least 3 items in the list
                        ' The last item at this point is the 'next link'
                        ' The second to last item is the current URL
                        ' The third-to-last item is the previous URL

                        ' This pops off the 'next link' which can be thrown away if we are going to the previous results
                        linksList.Pop()
                        if ( linksList.Count() > 1 ) then
                            ' This pops off the 'current URL' which can be thrown away if we are going to the previous results, since it will
                            ' be re-added via the doQuery call
                            linksList.Pop()
                            ' The final item is the previous item we meant to go view
                            theLink = linksList.Peek()
                        else
                            ' If there is one item left in the list, leave it alone since it is the initial subreddit link
                            theLink = linksList.Peek()
                        end if
                    end if
                    if ( theLink = invalid ) then
                        theLink = categories[category_idx].link
                    end if
                    ' Include a Back button, if there is more than one item left in the list
                    previous = linksList.Count() > 1
                    return { isContentList: true, content: doQuery( theLink, previous, categories[category_idx] ) }
                else if ( video[set_idx]["isPlaylist"] = true ) then
                    ' printAA( video[set_idx] )
                    if ( video[set_idx]["Source"] = getConstants().sYOUTUBE ) then
                        youtube.FetchVideoList( "GetPlaylistItems", video[set_idx]["TitleSeason"], false, {contentArg: video[set_idx]["PlaylistID"]}, "Loading playlist...", true )
                    else if ( video[set_idx]["Source"] = getConstants().sGOOGLE_DRIVE ) then
                        getGDriveFolderContents( video[set_idx] )
                    end if
                    return { isContentList: false, vidIdx: set_idx }
                else
                    vidIdx% = youtube.VideoDetails(video[set_idx], "/r/" + categories[category_idx].title, video, set_idx)
                    return { isContentList: false, content: video, vidIdx: vidIdx% }
                end if
            else
                print("Invalid video data")
            end if
        end function]
        uitkDoCategoryMenu( categoryList, screen, oncontent_callback, onclick_callback, onplay_callback, false, true )
End Sub

'******************************************************************************
' Helper function to query reddit, as well as build the metadata based on the response
' @param multireddits an optional URL with the multireddit to query, or the full link to parse. This is used when hitting the 'More Results' or 'Back' buttons on the video list page.
'     multireddits look like this: videos+funny+humor for /r/videos, /r/funny, and /r/humor
' @param includePrevious should a previous button be included in the results metadata?
' @param categoryObject the (optional) category object for the current subreddit (category)
'******************************************************************************
Function doQuery(multireddits = "videos" as String, includePrevious = false as Boolean, categoryObject = invalid as Dynamic) as Object
    response = QueryReddit( multireddits )
    if ( response.status = 403 ) then
        ShowErrorDialog(multireddits + " may be private, or unavailable at this time. Try again.", "403 Forbidden")
        return []
    end if
    if ( response.status <> 200 OR response.json = invalid OR response.json.kind <> "Listing" ) then
        ShowConnectionFailed()
        return []
    end if

    ' Everything is OK, display the list
    json = response.json
    metadata = GetRedditMetaData( NewRedditVideoList( json.data.children ) )

    ' Now add the 'More results' button
    if (response.links <> invalid AND response.links.next <> invalid) then
        metadata.Push({shortDescriptionLine1: "More Results", action: "next", HDPosterUrl:"pkg:/images/icon_next_episode.jpg", SDPosterUrl:"pkg:/images/icon_next_episode.jpg"})
        if ( categoryObject <> invalid ) then
            categoryObject.links.Push( response.links.next.href )
        end if
    end if
    if ( includePrevious = true ) then
        metadata.Unshift({shortDescriptionLine1: "Back", action: "prev", HDPosterUrl:"pkg:/images/icon_prev_episode.jpg", SDPosterUrl:"pkg:/images/icon_prev_episode.jpg"})
    end if

    return metadata
End Function

'******************************************************************************
' Runs the query against the reddit servers, and handles parsing the response
' @param multireddits an optional URL with the multireddit to query, or the full link to parse. This is used when hitting the 'More Results' or 'Back' buttons on the video list page.
'     multireddits look like this: videos+funny+humor for /r/videos, /r/funny, and /r/humor
' @return an roAssociativeArray containing the following members:
'               json = the JSON object represented as an roAssociativeArray
'               links = roArray of link objects containing the following members:
'                   func = callback function (ViewReddits)
'                   type = "next" or "previous"
'                   href = URL to the next or previous page of results
'               status = the HTTP status code response from the GET call
'******************************************************************************
Function QueryReddit(multireddits = "videos" as String) As Object
    prefs = getPrefs()
    method = "GET"
    if (Instr(0, multireddits, "http://")) then
        http = NewHttp( multireddits )
    else
        stub = "r"
        if (Instr(0, multireddits, ".")) then
            stub = "domain"
        else if (Instr(0, multireddits, "/m/")) then
            stub = "user"
        end if
        redditQueryType = LCase( firstValid( getEnumValueForType( getConstants().eREDDIT_QUERIES, prefs.getPrefValue( prefs.RedditFeed.key ) ), "Hot" ) )
        redditFilterType = LCase( firstValid( getEnumValueForType( getConstants().eREDDIT_FILTERS, prefs.getPrefValue( prefs.RedditFilter.key ) ), "All" ) )
        http = NewHttp("http://www.reddit.com/" + stub + "/" + multireddits + "/" + redditQueryType + ".json?t=" + redditFilterType)
    end if
    headers = {}

    http.method = method
    rsp = http.getToStringWithTimeout(10, headers)

    ' print "----------------------------------"
    ' print rsp
    ' print "----------------------------------"

    json = ParseJson(rsp)
    links = {}
    if (json <> invalid) then
        if (json.data.after <> invalid) then
            link = CreateObject("roAssociativeArray")
            link.func = doQuery
            link.type = "next"
            http.RemoveParam("after", "urlParams")
            http.AddParam("after", json.data.after, "urlParams")
            link.href = http.GetURL()
            links.next = link
        end if
        ' Reddit doesn't give a "real" previous URL
    end if
    returnObj = CreateObject("roAssociativeArray")
    returnObj.json = json
    returnObj.links = links
    returnObj.status = http.status
    return returnObj
End Function

'******************************************************************************
' Creates an roList of video objects, determining if they are from YouTube AND the ID was properly parsed from the URL
' @param jsonObject the JSON object that was received in QueryReddit
' @return an roList of video objects that are from YouTube AND have a valid video ID associated
'******************************************************************************
Function NewRedditVideoList(jsonObject As Object) As Object
    videoList = CreateObject( "roList" )
    constants = getConstants()
    for each record in jsonObject
        domain = LCase( record.data.domain ).Trim()
        supported = false
        if ( domain = "youtube.com" OR domain = "youtu.be" OR domain = "m.youtube.com" ) then
            video = NewRedditVideo( record )
            supported = true
        else if ( domain = "docs.google.com" OR domain = "drive.google.com" ) then
            video = NewRedditVideo( record, constants.sGOOGLE_DRIVE )
            supported = true
        else if ( domain = "gfycat.com" OR domain.InStr( 0, ".gfycat.com" ) > 0 ) then
            video = NewRedditGfycatVideo( record )
            supported = true
        else if ( domain = "liveleak.com" OR domain = "m.liveleak.com" ) then
            video = NewRedditURLVideo( record, constants.sLIVELEAK )
            video["URL"] = video["URL"] + "&ajax=1"
            supported = true
        else if ( domain = "vine.co" ) then
            video = NewRedditURLVideo( record, constants.sVINE )
            supported = true
        else if ( domain = "vidzi.tv" ) then
            video = NewRedditURLVideo( record, constants.sVIDZI )
            supported = true
        else if ( domain = "streamable.com" ) then
            video = NewRedditURLVideo( record, constants.sSTREAMABLE )
            supported = true
        else if ((domain = "imgur.com" OR domain.InStr( 0, ".imgur.com" ) > 0) AND record.data.url.inStr(0, ".gifv") > 0 ) then
            video = NewRedditURLVideo( record, constants.sIMGUR )
            supported = true
        end if
        if ( supported = true AND video <> invalid AND video["ID"] <> invalid AND video["ID"] <> "" ) then
            videoList.Push( video )
            video = invalid
        end if
    next
    return videoList
End Function

'********************************************************************
' Creates the list of categories from the provided XML
' @return an roList, which will be sorted by the yt:unreadCount if the XML
'         represents a list of subscriptions.
'********************************************************************
Function RedditCategoryList() As Object
    categoryList  = CreateObject("roList")
    subreddits = RegRead("subreddits", "reddit")
    if (subreddits <> invalid) then
        regex = CreateObject("roRegex", "\+", "") ' split on plus
        subredditArray = regex.Split(subreddits)
    else
        subredditArray = ["videos"]
    end if
    if ( getPrefs().getPrefValue( getConstants().pREDDIT_SORT ) = getConstants().ENABLED_VALUE ) then
        subArrayObject = CreateObject("roArray", subredditArray.Count(), true)
        for each item in subredditArray
            subArrayObject.push( item )
        next
        subArrayObject.Sort("i")
    else
        subArrayObject = subredditArray
    end if
    for each record in subArrayObject
        category        = CreateObject("roAssociativeArray")
        category.title  = record
        category.link   = record
        category.links  = []
        category.links.Push(category.link)
        categoryList.Push(category)
    next
    return categoryList
End Function

'******************************************************************************
' Creates a video roAssociativeArray, with the appropriate members needed to set Content Metadata and play a video with
' @param jsonObject the JSON "data" object that was received in QueryReddit, this is one result of many
' @return an roAssociativeArray of metadata for the current result
'******************************************************************************
Function NewRedditVideo(jsonObject As Object, source = "YouTube" as String) As Object
    video               = CreateObject("roAssociativeArray")
    ' The URL needs to be decoded prior to attempting to match
    decodedUrl = URLDecode( htmlDecode( jsonObject.data.url ) )
    yt = getYoutube()
    constants = getConstants()
    ytMatches = yt.ytIDRegex.Match( decodedUrl )
    url = jsonObject.data.url
    if ( jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid ) then
        url = jsonObject.data.media.oembed.url
    end if
    video["URL"] = url

    id = invalid

    ' Check for a video ID
    if ( source = constants.sYOUTUBE ) then
        if ( ytMatches.Count() > 1 ) then
            ' Default the PlayStart, since it is read later on
            video["PlayStart"] = 0
            ytUrl = NewHttp( decodedUrl )
            tParam = ytUrl.GetParams( "urlParams" ).get( "t" )
            if ( tParam <> invalid ) then
                ' This code gets the timestamp from the normal url param (?t or &t)
                if ( strtoi( tParam ) <> invalid ) then
                    if ( yt.regexTimestampHumanReadable.Match( tParam ).Count() = 0 ) then
                        video["PlayStart"]  = strtoi( tParam )
                    else
                        video["PlayStart"]  = get_human_readable_as_length( tParam )
                    end if
                end if
            else if ( ytUrl.anchor <> invalid AND ytUrl.anchor.InStr("t=") <> -1 ) then
                ' This set of code gets the timestamp from the anchor param (#t)
                playStart = ytUrl.anchor.Mid( ytUrl.anchor.InStr( "t=" ) + 2 )
                if ( strtoi( playStart ) <> invalid ) then
                    video["PlayStart"]  = strtoi( playStart )
                end if
            end if
            id = ytMatches[1]
            playlistId = getPlaylistId( decodedUrl )
            if ( playlistId <> invalid ) then
                video["HasPlaylist"] = true
                video["PlaylistID"]  = playlistId
            end if
        else
            ' Now check for a playlist link
            playlistId = getPlaylistId( decodedUrl )
            if ( playlistId <> invalid ) then
                video["isPlaylist"] = true
                id = playlistId
                video["PlaylistID"]  = playlistId
            else
                id = invalid
            end if
        end if
    else ' Google Drive
        regexFolderView = CreateObject( "roRegex", ".*folderview.*", "i" )
        if ( regexFolderView.IsMatch( url ) = true ) then
            video["isPlaylist"] = true
            id = url
            video["URL"] = id
        else
            id = url
        end if
    end if
    video["Source"]        = source
    video["ID"]            = id
    video["Title"]         = Left( htmlDecode( jsonObject.data.title ), 100)
    video["Category"]      = "/r/" + jsonObject.data.subreddit
    if ( firstValid( video[ "HasPlaylist" ], false ) = true ) then
        video["Category"] = video["Category"] + "      [Playlist Available - Hit * For More Options]"
    end if
    desc = ""
    if ( jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid ) then
        desc = jsonObject.data.media.oembed.description
    end if
    desc = firstValid( desc, "" )
    video["Description"]   = htmlDecode( desc )
    video["Linked"]        = MatchAll( yt.ytIDRegexForDesc, video["Description"] )
    video["Score"]         = jsonObject.data.score
    thumb = ""
    if (jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid) then
        thumb = URLDecode( htmlDecode( jsonObject.data.media.oembed.thumbnail_url ) )
    else
        thumb = URLDecode( htmlDecode( jsonObject.data.thumbnail ) )
    end if
    thumb = getDefaultThumb( thumb, source )
    video["Thumb"]         = thumb
    return video
End Function

'******************************************************************************
' Creates a video roAssociativeArray, with the appropriate members needed to set Content Metadata and play a video with
' This function handles Gfycat videos
' @param jsonObject the JSON "data" object that was received in QueryReddit, this is one result of many
' @return an roAssociativeArray of metadata for the current result
'******************************************************************************
Function NewRedditGfycatVideo(jsonObject As Object) As Object
    video               = CreateObject("roAssociativeArray")
    ' The URL needs to be decoded prior to attempting to match
    decodedUrl = URLDecode( htmlDecode( jsonObject.data.url ) )
    yt = getYoutube()
    gfycatMatches = yt.gfycatIDRegex.Match( decodedUrl )
    id = invalid
    if ( gfycatMatches.Count() > 1 ) then
        ' Default the PlayStart, since it is read later on
        video["PlayStart"] = 0
        id = gfycatMatches[1]
    end if
    video["Source"]        = getConstants().sGFYCAT
    video["ID"]            = id
    video["Title"]         = Left( htmlDecode( jsonObject.data.title ), 100)
    video["Category"]      = "/r/" + jsonObject.data.subreddit
    desc = ""
    if ( jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid ) then
        desc = jsonObject.data.media.oembed.description
    end if
    desc = firstValid( desc, "" )
    video["Description"]   = htmlDecode( desc )
    video["Linked"]        = []
    video["Score"]         = jsonObject.data.score
    thumb = ""
    if (jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid) then
        thumb = URLDecode( htmlDecode( jsonObject.data.media.oembed.thumbnail_url ) )
    else
        thumb = URLDecode( htmlDecode( jsonObject.data.thumbnail ) )
    end if
    thumb = getDefaultThumb( thumb, video["Source"] )
    video["Thumb"]         = thumb
    video["URL"]           = invalid
    return video
End Function

'******************************************************************************
' Creates a video roAssociativeArray, with the appropriate members needed to set Content Metadata and play a video with
' This function handles sites that require parsing a response for an MP4 URL (LiveLeak, Vine)
' @param jsonObject the JSON "data" object that was received in QueryReddit, this is one result of many
' @return an roAssociativeArray of metadata for the current result
'******************************************************************************
Function NewRedditURLVideo(jsonObject As Object, Source as String) As Object
    video               = CreateObject("roAssociativeArray")
    ' The URL needs to be decoded prior to attempting to match
    decodedUrl = URLDecode( htmlDecode( jsonObject.data.url ) )

    ' Default the PlayStart, since it is read later on
    video["PlayStart"] = 0
    video["Source"]        = Source
    video["ID"]            = decodedUrl
    video["Title"]         = Left( htmlDecode( jsonObject.data.title ), 100)
    video["Category"]      = "/r/" + jsonObject.data.subreddit
    desc = ""
    if ( jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid ) then
        desc = jsonObject.data.media.oembed.description
    end if
    desc = firstValid( desc, "" )
    video["Description"]   = htmlDecode( desc )
    video["Linked"]        = []
    video["Score"]         = jsonObject.data.score
    thumb = invalid
    if (jsonObject.data.media <> invalid AND jsonObject.data.media.oembed <> invalid) then
        thumb = URLDecode( htmlDecode( jsonObject.data.media.oembed.thumbnail_url ) )
    else
        thumb = URLDecode( htmlDecode( jsonObject.data.thumbnail ) )
    end if
    thumb = getDefaultThumb( thumb, source )
    video["Thumb"]         = thumb
    video["URL"]           = decodedUrl
    return video
End Function

Function getDefaultThumb( currentThumb as Dynamic, source as String ) as String
    if ( currentThumb = invalid OR ( Len( currentThumb ) = 0 ) OR currentThumb = "default" OR currentThumb = "nsfw" OR currentThumb.InStr( 0, "embed.ly" ) > 0 ) then
        constants = getConstants()
        if ( Source = constants.sYOUTUBE ) then
            currentThumb = "pkg:/images/no_thumb.jpg"
        else if ( Source = constants.sGOOGLE_DRIVE ) then
            currentThumb = "pkg:/images/GDrive.jpg"
        else if ( Source = constants.sGFYCAT ) then
            currentThumb = "pkg:/images/gfycat.png"
        else if ( Source = constants.sLIVELEAK ) then
            currentThumb = "pkg:/images/LiveLeak.jpg"
        else if ( Source = constants.sVINE ) then
            currentThumb = "pkg:/images/vine.jpg"
        else if ( Source = constants.sVIDZI ) then
            currentThumb = "pkg:/images/Vidzi.jpg"
        else if ( Source = constants.sSTREAMABLE ) then
            currentThumb = "pkg:/images/streamable.png"
        else if ( Source = constants.sIMGUR) then
            currentThumb = "pkg:/images/imgur.png"
        else
            currentThumb = "pkg:/images/no_thumb.jpg"
        end if
    end if
    return currentThumb
End Function

Function getPlaylistId( url as String ) as Dynamic
    retVal = invalid
    if ( url <> invalid ) then
        ytUrl = NewHttp( url )
        playlistId = ytUrl.GetParams( "urlParams" ).get( "list" )
        if ( playlistId <> invalid AND Len( playlistId.Trim() ) > 0 ) then
            retVal = playlistId
        end if
    end if
    return retVal
End Function

Function getPlaylistURL( playlistId as String ) as String
    return "http://gdata.youtube.com/feeds/api/playlists/" + playlistId
End Function

'******************************************************************************
' Custom metadata function needed to simplify displaying of content metadata for reddit results.
' This is necessary since the amount of metadata available for videos is much less than that available
' when querying YouTube directly.
' This will be called from doQuery
' It would be possible to Query YouTube for the additional metadata, but I don't know if that's worth it.
' @param videoList a list of video objects retrieved via the function NewRedditVideo
' @return an array of content metadata suitable for the Roku's screen objects.
'******************************************************************************
Function GetRedditMetaData(videoList As Object) as Object
    metadata = []

    for each video in videoList
        isPlaylist                     = firstValid( video[ "isPlaylist" ], false )
        hasPlaylist                    = firstValid( video[ "HasPlaylist" ], false )
        source                         = video[ "Source" ]
        meta                           = {}
        meta["ContentType"]            = "movie"
        meta["ID"]                     = video["ID"]
        meta["TitleSeason"]            = video["Title"]
        if ( isPlaylist = true ) then
            meta["Title"]              = "[" + source + " Playlist]"
        else
            if ( hasPlaylist ) then
                ' Mark the title with a + to denote it has a playlist (make it easier to see from the video list)
                source = source + "+"
            end if
            meta["Title"]              = "[" + source + "]"
        end if
        if ( video["Score"] <> invalid ) then
            meta["Title"] = meta["Title"] + " Score: " + tostr( video["Score"] )
        end if
        meta["Actors"]                 = meta["Title"]
        meta["FullDescription"]        = video["Description"]
        meta["Description"]            = Left( video["Description"], 300 )
        meta["Categories"]             = video["Category"]
        meta["ShortDescriptionLine1"]  = meta["TitleSeason"]
        meta["ShortDescriptionLine2"]  = meta["Title"]
        meta["SDPosterUrl"]            = video["Thumb"]
        meta["HDPosterUrl"]            = video["Thumb"]
        meta["StreamFormat"]           = "mp4"
        meta["Streams"]                = []
        meta["Linked"]                 = video["Linked"]
        meta["PlayStart"]              = video["PlayStart"]
        meta["Source"]                 = video["Source"]
        meta["URL"]                    = video["URL"]
        meta["isPlaylist"]             = isPlaylist
        meta["HasPlaylist"]            = hasPlaylist
        meta["PlaylistID"]             = firstValid( video[ "PlaylistID" ], invalid )
        metadata.Push(meta)
    end for

    return metadata
End Function

Sub EditRedditSettings()
    settingmenu = [
        {
            Title: "Show on Home Screen",
            HDPosterUrl:"pkg:/images/reddit.jpg",
            SDPosterUrl:"pkg:/images/reddit.jpg",
            prefData: getPrefs().getPrefData( getConstants().pREDDIT_ENABLED )
        },
        {
            Title: "Manage Subreddits",
            HDPosterUrl:"pkg:/images/reddit.jpg",
            SDPosterUrl:"pkg:/images/reddit.jpg",
            callback: "ManageSubreddits"
        },
        {
            Title: "Subreddits Sort",
            HDPosterUrl:"pkg:/images/reddit.jpg",
            SDPosterUrl:"pkg:/images/reddit.jpg",
            prefData: getPrefs().getPrefData( getConstants().pREDDIT_SORT )
        },
        {
            Title: "Reddit Feed to Display",
            HDPosterUrl:"pkg:/images/reddit.jpg",
            SDPosterUrl:"pkg:/images/reddit.jpg",
            prefData: getPrefs().getPrefData( getConstants().pREDDIT_FEED )
        },
        {
            Title: "Reddit Filter to Apply",
            HDPosterUrl:"pkg:/images/reddit.jpg",
            SDPosterUrl:"pkg:/images/reddit.jpg",
            prefData: getPrefs().getPrefData( getConstants().pREDDIT_FILTER )
        }
    ]

    uitkPreShowListMenu( m, settingmenu, "Reddit Preferences", "Preferences", "Reddit" )
End Sub

Sub ManageSubreddits_impl()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSearchScreen")
    screen.SetMessagePort(port)

    history = CreateObject("roSearchHistory")
    subreddits = RegRead("subreddits", "reddit")
    subredditArray = []
    if (subreddits <> invalid) then
        regex = CreateObject("roRegex", "\+", "") ' split on plus
        for each subreddit in regex.Split( subreddits )
            subredditArray.Push( subreddit )
        next
    else
        subredditArray.Push( "videos" )
    end if
    screen.SetSearchTerms( subredditArray )
    screen.SetBreadcrumbText( "", "Hit the * button to remove a subreddit" )
    screen.SetSearchTermHeaderText( "Current Subreddits:" )
    screen.SetClearButtonText( "Remove All" )
    screen.SetSearchButtonText( "Add Subreddit" )
    screen.SetEmptySearchTermsText( "If you want to disable the reddit channel, do it from the previous screen." )
    screen.Show()
    filteredResults = []
    while (true)
        msg = wait(2000, port)

        if (type(msg) = "roSearchScreenEvent") then
            'print "Event: "; msg.GetType(); " msg: "; msg.GetMessage()
            if (msg.isScreenClosed()) then
                exit while
            else if (msg.isPartialResult()) then
                filteredResults = filterSubreddits( subredditArray, msg.GetMessage() )
                screen.SetSearchTerms( filteredResults )
            else if (msg.isFullResult()) then
                ' Check to see if they're trying to add a duplicate subreddit, or empty string
                newOne = msg.GetMessage().Trim()
                if ( Len( newOne ) > 0 ) then
                    if ( getSubredditIndex( subredditArray, newOne ) = -1 ) then
                        subredditArray.Push( newOne )
                        screen.SetSearchTerms( subredditArray )
                    end if
                    ' When the user hits 'Add Subreddit' or hits ok on a subreddit on the right side, set the search text
                    ' to make it easier to edit mistakes
                    screen.SetSearchText( newOne )
                end if
            else if (msg.isCleared()) then
                filteredResults.Clear()
                subredditArray.Clear()
                screen.ClearSearchTerms()
            else if ( msg.isButtonInfo() ) then
                ' Bug: This event is fired when focus is on the buttons on the bottom of the search screen with an index of 0
                msgIndex% = msg.GetIndex()
                ' print "msgIndex: " ; msgIndex%
                if ( subredditArray.Count() > 0 ) then
                    if ( filteredResults.Count() > 0 ) then
                        subredditIndex = getSubredditIndex( subredditArray, filteredResults[ msgIndex% ] )
                        if ( subredditIndex <> -1 ) then
                            filteredResults.Delete( msgIndex% )
                            subredditArray.Delete( subredditIndex )
                            screen.SetSearchTerms( filteredResults )
                        else
                            print "Couldn't match filtered subreddit to full array!"
                        end if
                    else
                        subredditArray.Delete( msgIndex% )
                        screen.SetSearchTerms( subredditArray )
                    end if
                end if
            'else
            '    print "Unhandled event on search screen Event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
    ' Save the user's subreddits when the settings screen is closing
    subString = ""
    if ( subredditArray.Count() > 0 ) then
        for i = 0 to subredditArray.Count() - 1
            subString = subString + subredditArray[i]
            if ( i < subredditArray.Count() - 1 ) then
                subString = subString + "+"
            end if
        next
        RegWrite( "subreddits", subString, "reddit" )
    else
        ' If their list is empty, just remove the unused registry key
        RegDelete( "subreddits", "reddit" )
    end if
End Sub

Function getSubredditIndex( subredditArray as Object, subredditToFind as String ) as Integer
    result = -1
    for idx = 0 to subredditArray.Count() - 1
        subredditText = subredditArray[ idx ]
        if ( LCase( subredditText.Trim() ) = LCase( subredditToFind.Trim() ) ) then
            result = idx
            exit for
        end if
    next
    return result
End Function

Function filterSubreddits( subreddits as Object, filterText as String ) as Object
    if ( subreddits.Count() = 0 OR filterText = invalid OR Len( filterText ) = 0 ) then
        return subreddits
    end if
    result = []
    for each subreddit in subreddits
        if ( LCase( subreddit.Trim() ).Instr( 0, LCase( filterText.Trim() ) ) <> -1 ) then
            result.Push( subreddit )
        end if
    end for
    return result
End Function
