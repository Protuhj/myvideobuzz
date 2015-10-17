
Sub Init()
    if (m.youtube = invalid) then
        m.youtube = InitYouTube()
    end if

    if ( m.constants = invalid ) then
        m.constants = LoadConstants()
    end if

    if ( m.prefs = invalid ) then
        m.prefs = LoadPreferences()
    end if
End Sub

Function getYoutube() As Object
    ' global singleton
    return m.youtube
End Function

Function getConstants() as Object
    return m.constants
End Function

Function getPrefs() as Object
    return m.prefs
End Function

Sub RunUserInterface()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()
    ShowHomeScreen()
End Sub


Sub ShowHomeScreen()
    ' Pop up start of UI for some instant feedback while we load the icon data
    Init()
    youtube = getYoutube()
    screen = uitkPreShowPosterMenu("flat-category", youtube.userName)
    if (screen = invalid) then
        print "Failed to create the home screen!"
        return
    end if

    if (youtube.home_screen <> invalid) then
        youtube.home_screen.close()
        youtube.home_screen = invalid
    end if
    consts = getConstants()
    prefs = getPrefs()
    ' First see if someone is updating their channel, and may not have loaded their channel ID yet.
    if (youtube.userName <> invalid AND youtube.channelId = invalid) then
        result = findChannelID( youtube.userName )
        if (result = invalid) then
            if (ShowDialog2Buttons("Error", "It appears your YouTube User ID is invalid, would you like to attempt to fix this?", "Not Now", "Yes") = 2 ) then
                youtube.AddAccount()
            end if
        else
            RegWrite( "ytChannelId", result.Trim() )
            youtube.channelId = result.Trim()
            print "Successfully found a valid channel id!" ; result.Trim()
        end if
    end if
    menudata=[]
    if (youtube.channelId <> invalid) and (isnonemptystr(youtube.channelId)) then
        menudata.Push({ShortDescriptionLine1:"What to Watch", OnClick: "GetWhatsNew", ShortDescriptionLine2:"What's new to watch", HDPosterUrl:"pkg:/images/whattowatch.jpg", SDPosterUrl:"pkg:/images/whattowatch.jpg"})
        menudata.Push({ShortDescriptionLine1:"My Playlists", ContentFunc: "MyPlaylists", categoryData:{ isPlaylist: true, itemFunc: "GetPlaylistItems"}, ShortDescriptionLine2:"Browse your Playlists", HDPosterUrl:"pkg:/images/YourPlaylists.jpg", SDPosterUrl:"pkg:/images/YourPlaylists.jpg"})
        menudata.Push({ShortDescriptionLine1:"My Subscriptions", ContentFunc: "MySubscriptions", categoryData:{ isPlaylist: true, itemFunc: "GetVideosActivity"}, ShortDescriptionLine2:"Browse your Subscriptions", HDPosterUrl:"pkg:/images/YourSubscriptions.jpg", SDPosterUrl:"pkg:/images/YourSubscriptions.jpg"})
        'TEMP? menudata.Push({ShortDescriptionLine1:"My Favorites", FeedURL:"users/" + ytusername + "/favorites?v=2&max-results=50&safeSearch=none", categoryData: invalid, ShortDescriptionLine2:"Browse your favorite videos", HDPosterUrl:"pkg:/images/YourFavorites.jpg", SDPosterUrl:"pkg:/images/YourFavorites.jpg"})
    end if
    menudata.Push({ShortDescriptionLine1:"Search", OnClick:"SearchYoutube", ShortDescriptionLine2:"Search YouTube for videos",  HDPosterUrl:"pkg:/images/Search.jpg", SDPosterUrl:"pkg:/images/Search.jpg"})
    if ( prefs.getPrefValue( consts.pREDDIT_ENABLED ) = consts.ENABLED_VALUE ) then
        menudata.Push({ShortDescriptionLine1:"Reddit", ShortDescriptionLine2: "Browse videos from reddit", Custom: true, ViewFunc: ViewReddits, HDPosterUrl:"pkg:/images/reddit.jpg", SDPosterUrl:"pkg:/images/reddit.jpg"})
    end if
    if ( prefs.getPrefValue( consts.pTWITCH_ENABLED ) = consts.ENABLED_VALUE ) then
        menudata.Push({ShortDescriptionLine1:"Twitch", ShortDescriptionLine2: "Browse videos from Twitch.tv", Custom: true, ViewFunc: ViewTwitch, HDPosterUrl:"pkg:/images/twitch.jpg", SDPosterUrl:"pkg:/images/twitch.jpg"})
    end if
    menudata.Push({ShortDescriptionLine1:"History", OnClick:"ShowHistory", ShortDescriptionLine2:"View your history",  HDPosterUrl:"pkg:/images/History.png", SDPosterUrl:"pkg:/images/History.png"})
    if ( prefs.getPrefValue( consts.pLAN_VIDEOS_ENABLED ) = consts.ENABLED_VALUE ) then
        menudata.Push({ShortDescriptionLine1:"Local Network (Requires Multiple Rokus)", Custom: true, ViewFunc: CheckForLANVideos, categoryData:invalid, ShortDescriptionLine2:"Recent videos from other MyVideoBuzz channels running on your LAN.", HDPosterUrl:"pkg:/images/LAN.jpg", SDPosterUrl:"pkg:/images/LAN.jpg"})
    end if

    'menudata.Push({ShortDescriptionLine1:"Top Channels", FeedURL:"pkg:/xml/topchannels.xml", categoryData:{ isPlaylist: false },  ShortDescriptionLine2:"Top Channels", HDPosterUrl:"pkg:/images/TopChannels.jpg", SDPosterUrl:"pkg:/images/TopChannels.jpg"})
    menudata.Push({ShortDescriptionLine1:"Most Popular", OnClick:"MostPopular", ShortDescriptionLine2:"Most Popular Videos", HDPosterUrl:"pkg:/images/MostPopular.jpg", SDPosterUrl:"pkg:/images/mostpopular.jpg"})
    menudata.Push({ShortDescriptionLine1:"Settings", OnClick:"BrowseSettings", ShortDescriptionLine2:"Edit channel settings", HDPosterUrl:"pkg:/images/Settings.jpg", SDPosterUrl:"pkg:/images/Settings.jpg"})

    onselect = [1, menudata, m.youtube,
        function(menu, youtube, set_idx)
            if (menu[set_idx]["ContentFunc"] <> invalid) then
                youtube.FetchVideoList(menu[set_idx]["ContentFunc"],menu[set_idx]["ShortDescriptionLine1"], true, menu[set_idx]["categoryData"])
            else if (menu[set_idx]["OnClick"] <> invalid) then
                onclickevent = menu[set_idx]["OnClick"]
                youtube[onclickevent]()
            else if (menu[set_idx]["Custom"] = true) then
                    menu[set_idx]["ViewFunc"](youtube)
            end if
            return set_idx
        end function]
    MulticastInit(youtube)
    ' If "updatePending" exists in the registry, then we are booting from the update process (hopefully).
    updatePending = RegRead("updatePending")
    if ( updatePending = invalid ) then
        if ( prefs.getPrefValue( consts.pAUTO_UPDATE ) = consts.sUPDATE_REL ) then
            CheckForNewRelease( true )
        else if ( prefs.getPrefValue( consts.pAUTO_UPDATE ) = consts.sUPDATE_NEW ) then
            CheckForNewMaster( true )
        end if
    else
        RegDelete("updatePending")
        versionStr = consts.VERSION_STR

        manifestText = ReadAsciiFile( "pkg:/manifest" )
        manifestData = ParseManifestString( manifestText )
        if ( manifestData <> invalid ) then
            versionStr = manifestData.versionStr
        end if
        if ( ShowDialog2Buttons( "Update Complete", "Successfully updated to version " + versionStr +". Would you like to view what's new?", "Not Now", "Yes" ) = 2 ) then
            youtube.WhatsNew()
        end if
    end if
    youtube.home_screen = screen

    ' Code to test specific video IDs
    ' Each of these is age-restricted.
    'ids = []
    'https://www.youtube.com/watch?v=PRZjnGUGXBI
    'ids.push("PRZjnGUGXBI") ' VEVO turd
    'ids.push("1EROmqidZQc")
    'ids.push("kP8O-MOqmcw")
    'ids.push("nje6dcArZrI")
    'ids.push("UMyoCr2MnpM")
    'ids.push("5_yOGBzBTdc")
    'youtube.FetchVideoList( "ExecBatchQueryV3", "Vidyas", false, { contentArg: ids, noPages: true} )

    ' Testing out a specific playlist
    'youtube.FetchVideoList("GetPlaylistItems", "Blah", false, {contentArg: "PL30BFB50685A0252B"})

    uitkDoPosterMenu(menudata, screen, onselect)

    sleep(25)
End Sub

Function GetOne() as Dynamic
    retVal = []
    retVal.Push( 52 )
    retVal.Push( 60 )
    retVal.Push( 109 )
    retVal.Push( 84 )
    retVal.Push( 70 )
    retVal.Push( 108 )
    retVal.Push( 53 )
    retVal.Push( 84 )
    retVal.Push( 75 )
    retVal.Push( 93 )
    retVal.Push( 43 )
    retVal.Push( 38 )
    retVal.Push( 103 )
    return retVal
End Function

'*************************************************************
'** Set the configurable theme attributes for the application
'**
'** Configure the custom overhang and Logo attributes
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "31"
    theme.OverhangSliceSD = "pkg:/images/Overhang_Background_SD.png"
    theme.OverhangLogoSD  = "pkg:/images/Overhang_Logo_SD.png"

    theme.OverhangOffsetHD_X = "125"
    theme.OverhangOffsetHD_Y = "25"
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_HD.png"
    theme.BackgroundColor = "#232B30"

    textColor = "#B7DFF8"
    theme.ListScreenTitleColor      = "#92b2c6"
    theme.ListScreenDescriptionText = "#92b2c6"
    theme.ListScreenHeaderText      = "#92b2c6"
    theme.GridScreenListNameColor   = "#FFFFFF"
    theme.GridScreenMessageColor   = "#FFFFFF"
    theme.GridScreenRetrievingColor   = "#FFFFFF"
    theme.TextScreenBodyBackgroundColor   = "#FFFFFF"
    theme.ListItemText              = textColor
    theme.ListItemHighlightText     = textColor
    theme.PosterScreenLine1Text     = textColor
    theme.PosterScreenLine2Text     = textColor
    theme.EpisodeSynopsisText       = textColor
    theme.ParagraphBodyText         = textColor
    theme.ParagraphHeaderText       = textColor
    theme.SpringboardTitleText      = textColor
    theme.SpringboardRuntimeColor   = textColor
    theme.SpringboardGenreColor     = textColor
    theme.SpringboardSynopsisColor  = textColor
    theme.SpringboardAllow6Buttons  = "true"

    theme.FilterBannerActiveColor   = textColor
    theme.ButtonMenuNormalText   = textColor
    theme.ButtonHighlightColor   = textColor

    app.SetTheme(theme)
End Sub



