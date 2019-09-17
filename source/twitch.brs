'******************************************************************************
' Twitch.brs
' Adds support for handling Twitch's json feed for livestreams
' Documentation on the API is here:
'             www.johannesbader.ch/2014/01/find-video-url-of-twitch-tv-live-streams-or-past-broadcasts/
'           and here:
'             https://github.com/justintv/twitch-api
'******************************************************************************

'******************************************************************************
' Main function to begin displaying Twitch content
' @param youtube the current youtube instance
' @param url an optional URL with the multireddit to query, or the full link to parse. This is used when hitting the 'More Results' or 'Back' buttons on the video list page.
'     multireddits look like this: videos+funny+humor for /r/videos, /r/funny, and /r/humor
'******************************************************************************
Sub ViewTwitch(youtube as Object, urlToQuery = "https://api.twitch.tv/helix/games/top" as String )
    title = "Twitch Games"
    screen = uitkPreShowPosterMenu( "arced-portrait", title )
    screen.showMessage( "Loading Twitch games..." )
    rsp = QueryForJson( urlToQuery, GetAddendum() )

    if ( rsp.status = 200 ) then
        gameList = newTwitchGameList( rsp.json )
        ' Now add the 'More results' button
        if ( rsp.json.pagination <> invalid AND rsp.json.pagination.cursor <> invalid ) then
            newURL = NewHttp( urlToQuery )
            ' Remove the old value first, otherwise it doesn't get replaced
            newURL.RemoveParam( "after", "urlParams" )
            newURL.AddParam( "after", rsp.json.pagination.cursor, "urlParams" )
            gameList.Push({shortDescriptionLine1: "More Results", action: "next", pageURL: newURL.GetURL(), HDPosterUrl:"pkg:/images/twitch_more.jpg", SDPosterUrl:"pkg:/images/twitch_more.jpg"})
        end if
        twitchUserName = getPrefs().getPrefValue( getConstants().pTWITCH_USER_NAME )
        if ( Len( twitchUserName.Trim() ) > 0 ) then
            gameList.Unshift({shortDescriptionLine1: "Followed Channels", special: "followed", username: twitchUserName, HDPosterUrl:"pkg:/images/twitch_followed.jpg", SDPosterUrl:"pkg:/images/twitch_followed.jpg"})
        end if

        onselect = [1, gameList, youtube,
        function(menu, youtube, set_idx)
            if (menu[set_idx]["action"] <> invalid) then
                ViewTwitch(youtube, menu[set_idx]["pageURL"] )
            else if ( menu[set_idx]["special"] = "followed" ) then
                showUserFollowed( menu[set_idx]["username"] )
            else
                ViewTwitchStreams( menu[set_idx]["TitleSeason"], invalid, menu[set_idx]["ID"] )
            end if
            return set_idx
        end function]
        uitkDoPosterMenu( gameList, screen, onselect )
    else
        ShowErrorDialog( "Error querying Twitch (Code: " + tostr( rsp.status ) + ")", "Twitch Error" )
    end if
End Sub

'******************************************************************************
' Function to show a user's followed channels.
' @param userName The user name of the user to get followed channels for
'******************************************************************************
Sub showUserFollowed( userName as String )
    userID = getUserID( userName )
    if ( userID <> invalid ) then
        urlToQuery = "https://api.twitch.tv/helix/users/follows?from_id=" + userID + "&first=100"
        rsp = QueryForJson( urlToQuery, GetAddendum())
        if ( rsp.status = 200 ) then
            if ( rsp.json.data = invalid OR rsp.json.data.Count() = 0 ) then
                ShowErrorDialog( "Found no followed channels for user: '" + userName + "'", "Error" )
            else
                channelsList = ""
                for each entry in rsp.json.data
                    channelsList = channelsList + "&user_id=" + entry.to_id
                next
                ViewTwitchStreams( "Followed Channels", "https://api.twitch.tv/helix/streams?first=50" + channelsList )
            end if
        else
            ShowErrorDialog( "Error querying Twitch (Code: " + tostr( rsp.status ) + ") Ensure you entered your username (" + userName + ") correctly!", "Twitch Error" )
        end if
    end if
End Sub

Function getUserID( userName as String )
    urlToQuery = "https://api.twitch.tv/helix/users?login=" + userName.Trim()
    rsp = QueryForJson( urlToQuery, GetAddendum() )
    if ( rsp.status = 200 ) then
        if ( rsp.json.data = invalid OR rsp.json.data.Count() = 0 ) then
            ShowErrorDialog( "Failed to get user data for user: '" + userName + "'", "Error" )
        else
            return rsp.json.data[0].id
        end if
    else
        ShowErrorDialog( "Error querying Twitch (Code: " + tostr( rsp.status ) + ") Ensure you entered your username (" + userName + ") correctly!", "Twitch Error" )
    end if
    return invalid
End Function

'******************************************************************************
' Main function to begin displaying Twitch content
' @param youtube the current youtube instance
'******************************************************************************
Sub ViewTwitchStreams(gameName as String, urlToQuery = invalid as dynamic, gameID = invalid as Dynamic )
    title = gameName
    screen = uitkPreShowPosterMenu( "flat-episodic-16x9", title )
    screen.showMessage( "Loading Streams for " + title )
    if ( urlToQuery = invalid ) then
        urlToQuery = "https://api.twitch.tv/helix/streams?first=50&game_id=" + gameID
    end if
    rsp = QueryForJson( urlToQuery, GetAddendum())

    if ( rsp.status = 200 ) then
        streamList = NewTwitchStreamList( rsp.json )

        if ( streamList.Count() > 0 ) then
            ' Now add the 'More results' button
            if ( rsp.json.pagination <> invalid AND rsp.json.pagination.cursor <> invalid ) then
                newURL = NewHttp( urlToQuery )
                ' Remove the old value first, otherwise it doesn't get replaced
                newURL.RemoveParam( "after", "urlParams" )
                newURL.AddParam( "after", rsp.json.pagination.cursor, "urlParams" )
                streamList.Push({shortDescriptionLine1: "More Results", action: "next", pageURL: newURL.GetURL(), HDPosterUrl:"pkg:/images/icon_next_episode.jpg", SDPosterUrl:"pkg:/images/icon_next_episode.jpg"})
            end if

            onselect = [1, streamList, title,
            function(menu, title, set_idx)
                if (menu[set_idx]["action"] <> invalid) then
                    ViewTwitchStreams( title, menu[set_idx]["pageURL"] )
                else
                    newTwitchVideo( menu[set_idx]["ChannelName"] )
                end if
                return set_idx
            end function]
            uitkDoPosterMenu( streamList, screen, onselect, onplay_callback_Twitch )
        else
            ShowErrorDialog( "No more live streams!", "No Live Streams" )
        end if
    else
        ShowErrorDialog( "Error querying Twitch (Code: " + tostr( rsp.status ) + ")", "Twitch Error" )
    end if
End Sub

Function GetAddendums() as Dynamic
    return "k674du" + "51oxdhbjosmt" + "tm1tnfgr57zyd"
End Function

Function NewTwitchGameList(jsonObject As Object) As Object
    gameList = []
    for each record in jsonObject.data
        gameList.Push( NewTwitchGameLink( record ) )
    next
    return gameList
End Function

Function NewTwitchStreamList(jsonObject As Object) As Object
    streamList = []
    for each record in jsonObject.data
        streamList.Push( NewTwitchStreamLink( record ) )
    next
    return streamList
End Function

Sub updateTwitchSubHLSText( m3u8URL as String )
    if ( m3u8URL <> invalid ) then
        headers = { }
        headers["User-Agent"] = getConstants().USER_AGENT
        http = NewHttp( m3u8URL )
        hlsText = http.getToStringWithTimeout(10, headers)
        if ( http.status = 200 AND hlsText <> invalid ) then
            'liveRegex = CreateObject( "roRegex", ",live", "ig" )
            ' This line apparently causes Roku to not parse properly
            ' Will probably cause streams to drop if the broadcaster decides to play an Ad
            'testRegex = CreateObject( "roRegex", "#EXT-X-PROGRAM-DATE-TIME.*\n", "ig" )
            dateRegex = CreateObject( "roRegex", "#EXT-X-DATERANGE.*\n", "ig" )
            'hlsText = liveRegex.ReplaceAll( hlsText, ",live," )
            hlsText = dateRegex.ReplaceAll( hlsText, "" )
            getYoutube().dashManifestContents = hlsText
            'print "New manifest text: " ; getYoutube().dashManifestContents
        else
            print "Failed to update Twitch HLS text!"
            getYoutube().dashManifestContents = invalid
        end if
    else
        print "No Twitch m3u8 URL"
        getYoutube().dashManifestContents = invalid
    end if
End Sub

Function MatchAllURLs(regex as Object, text As String) As Object
   response = Left(text, Len(text))
   values = {}
   matches = regex.Match( response )
   iLoop = 0
   while ( matches.Count() > 2 )
      values[ matches[ 1 ] ] = matches[2]
      ' remove this instance, so we can get the next match
      response = regex.Replace( response, "" )
      matches = regex.Match( response )
      ' if we've looped more than 50 times, then we're probably stuck, so exit
      iLoop = iLoop + 1
      if ( iLoop > 50 ) Then
        exit while
      end if
   end while
   return values
End Function

Sub newTwitchVideo( channel as String )
    result = QueryForJson( "https://api.twitch.tv/api/channels/" + channel + "/access_token?need_https=true&as3=t&allow_source=true", GetAddendum() )
    'print "Sig: " ; result.json.sig
    'print "Token: " ; result.json.token
    getYoutube().dashManifestContents = invalid
    getYoutube().twitchM3U8URL = invalid
    if ( result <> invalid AND result.status = 200 ) then
        meta                   = {}
        meta["Author"]                 = channel
        meta["TitleSeason"]            = channel + " Live"
        meta["Title"]                  = meta["Author"]
        meta["Actors"]                 = meta["Author"]
        meta["FullDescription"]        = "Live Stream"
        meta["Description"]            = "Twitch Live Stream"
        meta["Categories"]             = "Live Stream"
        meta["ShortDescriptionLine1"]  = meta["TitleSeason"]
        meta["ShortDescriptionLine2"]  = meta["Title"]
        meta["SDPosterUrl"]            = getDefaultThumb( invalid, "" )
        meta["HDPosterUrl"]            = getDefaultThumb( invalid, "" )
        meta["Length"]                 = 0
        meta["UserID"]                 = channel
        meta["StreamFormat"]           = "hls"
        meta["MaxBandwidth"]           = firstValid( getEnumValueForType( getConstants().eHLS_MAX_BANDWIDTH, getPrefs().getPrefValue( getConstants().pHLS_MAX_BANDWIDTH ) ), "0" ).ToInt()
        meta["Live"]                   = true
        meta["Streams"]                = []
        meta["Source"]                 = getConstants().sTWITCH
        ' Set the PlayStart sufficiently large so it starts at 'Live' position
        meta["PlayStart"]              = 500000
        meta["SwitchingStrategy"]      = "full-adaptation"
        hlsUrl = "http://usher.twitch.tv/api/channel/hls/" + LCase(channel) + ".m3u8?sig=" + result.json.sig +"&token=" + result.json.token + "&allow_spectre=false"
        headers = { }
        headers["User-Agent"] = getConstants().USER_AGENT
        http = NewHttp( hlsUrl )
        hlsText = http.getToStringWithTimeout(10, headers)
        if ( http.status = 200 AND hlsText <> invalid ) then
            ' Roku doesn't handle the sub-M3U8 file format, specifically the #EXT-X-DATERANGE tag
            ' so, we gotta serve the sub M3U8 file ourselves, rather than relying on the Roku querying the server for it
            ' we've gotta query it ourselves, and make sure the offending line is removed
            regex720p30 = CreateObject( "roRegex", "VIDEO=" + Quote() + "([\w]+?)" + Quote() + "[^#]*?(http.*?\.m3u8)", "igs" )
            urlResult = MatchAllURLs( regex720p30, hlsText )
            PrintAny( 0, "A: ", urlResult )
            for each key in urlResult
                regexDoReplace = CreateObject ( "roRegex", urlResult[key], "ig" )
                hlsText = regexDoReplace.ReplaceAll( hlsText, "http://localhost:6789/" + key )
            next
            getYoutube().twitchM3U8URL = urlResult
            print hlsText
            getYoutube().dashManifestContents = hlsText
            meta["Streams"].Push({url: "http://localhost:6789", bitrate: 0, quality: false, contentid: -1})
            DisplayVideo(meta)
        else
            ShowErrorDialog( "Error querying Twitch (Code: " + tostr( http.status ) + ")", "Twitch Error" )
        end if
    else
        ShowErrorDialog( "Error querying Twitch (Code: " + tostr( result.status ) + ")", "Twitch Error" )
    end if
End Sub

'******************************************************************************
' Creates a video roAssociativeArray, with the appropriate members needed to set Content Metadata and play a video with
' This function handles sites that require parsing a response for an MP4 URL (LiveLeak, Vine)
' @param jsonObject the JSON "data" object that was received in QueryForJson, this is one result of many
' @return an roAssociativeArray of metadata for the current result
'******************************************************************************
Function NewTwitchGameLink(jsonObject As Object) As Object
    game                   = {}
    game["ID"]                      = tostr( jsonObject.id )
    game["TitleSeason"]             = jsonObject.name
    game["Categories"]              = "Vidya Game"
    game["Source"]                  = getConstants().sTWITCH
    game["Thumb"]                   = jsonObject.box_art_url
    game["ContentType"]             = "game"
    'game["Title"]                   = "Viewers: " + tostr( jsonObject.viewers )
    game["FullDescription"]         = ""
    game["Description"]             = tostr( jsonObject.channels ) + " Channels"
    game["ShortDescriptionLine1"]   = game["TitleSeason"]
    game["ShortDescriptionLine2"]   = game["Title"]
    game["SDPosterUrl"]             = jsonObject.box_art_url.replace( "{width}", "158" ).replace( "{height}", "204" )
    game["HDPosterUrl"]             = jsonObject.box_art_url.replace( "{width}", "214" ).replace( "{height}", "306" )
    return game
End Function

'******************************************************************************
' Creates a video roAssociativeArray, with the appropriate members needed to set Content Metadata and play a video with
' @param jsonObject the JSON "data" object that was received in QueryForJson, this is one result of many
' @return an roAssociativeArray of metadata for the current result
'******************************************************************************
Function NewTwitchStreamLink(jsonObject As Object) As Object
    game                   = {}
    game["ID"]                      = jsonObject.game_id
    game["ChannelName"]             = jsonObject.user_name
    if ( jsonObject.language <> invalid ) then
        game["TitleSeason"] = jsonObject.user_name + " [Lang: " + UCase(jsonObject.language) + "]"
    else
        game["TitleSeason"] = jsonObject.user_name
    end if
    'game["Categories"]              = jsonObject.game
    game["Source"]                  = getConstants().sTWITCH
    game["Thumb"]                   = jsonObject.thumbnail_url
    game["ContentType"]             = "game"
    'game["Title"]                   = jsonObject.channel.game + " [Viewers: " + tostr( jsonObject.viewer_count ) + "]"
    game["Title"]                   = "[Viewers: " + tostr( jsonObject.viewer_count ) + "]"
    game["FullDescription"]         = jsonObject.title
    game["Description"]             = jsonObject.title
    game["ShortDescriptionLine1"]   = game["TitleSeason"]
    game["ShortDescriptionLine2"]   = game["Title"]
    game["SDPosterUrl"]             = jsonObject.thumbnail_url.replace( "{width}", "285" ).replace( "{height}", "145" )
    game["HDPosterUrl"]             = jsonObject.thumbnail_url.replace( "{width}", "385" ).replace( "{height}", "218" )
    return game
End Function

Sub EditTwitchSettings()
    settingmenu = [
        {
            Title: "Show on Home Screen",
            HDPosterUrl:"pkg:/images/twitch.jpg",
            SDPosterUrl:"pkg:/images/twitch.jpg",
            prefData: getPrefs().getPrefData( getConstants().pTWITCH_ENABLED )
        },
        {
            Title: "Your Twitch User Name",
            HDPosterUrl:"pkg:/images/icon_key.jpg",
            SDPosterUrl:"pkg:/images/icon_key.jpg",
            prefData: getPrefs().getPrefData( getConstants().pTWITCH_USER_NAME )
        }
    ]

    uitkPreShowListMenu( m, settingmenu, "Twitch Preferences", "Preferences", "Twitch" )
End Sub

'********************************************************************
' Callback function for when the user hits the play button from the Stream list for Twitch
' @param theVideo the video metadata object that should be played.
'********************************************************************
Sub onplay_callback_Twitch(theVideo as Object)
    newTwitchVideo( theVideo["ChannelName"] )
End Sub

Function GetAddendum( num = 61 as Integer ) as Dynamic
    retVal2 = ""
    retVal = []
    base = 99
    retVal.Push( base - 32 )
    base = base + 9
    retVal.Push( base )
    base = base - 3
    retVal.Push( base )
    base = base - 4
    retVal.Push( base )
    base = base + 9
    retVal.Push( base )
    base = base + 6
    retVal.Push( base )
    base = base - 21
    retVal.Push( base - 50 )
    base = base + 10
    retVal.Push( base - 32 )
    base = base - 5
    retVal.Push( base - 32 )
    'base = base - 42
    'retVal.Push( base )
    for each item in retVal
        retVal2 = retVal2 + Chr( item )
    end for
    finalRet = {}
    finalRet[retVal2] = GetAddendums()
    return finalRet
End Function
