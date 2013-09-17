
Sub Init()
    'if m.oa = invalid then m.oa = InitOauth("RokyouTube", "toasterdesigns.net", "Y6GQqc19mQ2Q5Ux4PFxMOUPk", "1.0")
    if (m.youtube = invalid) then
        m.youtube = InitYouTube()
    end if
End Sub

Sub RunUserInterface()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()
    ShowHomeScreen()
End Sub


Sub ShowHomeScreen()
    ' Pop up start of UI for some instant feedback while we load the icon data
    ytusername = RegRead("YTUSERNAME1", invalid)
    screen=uitkPreShowPosterMenu("flat-category", ytusername)
    if (screen = invalid) then
        'print "unexpected error in uitkPreShowPosterMenu"
        return
    end if

    Init()
'    oa = Oauth()
    youtube = LoadYouTube()

  '  if doRegistration() <> 0 then
   '     reason = "unknown"
    '    if not oa.linked() then reason = "unlinked"
     '   print "Main: exit due to error in registration, reason: "; reason
        'exit the app gently so that the screen doesn't flash to black
      '  sleep(25)
       ' return
    'end if

    menudata=[]

    menudata.Push({ShortDescriptionLine1:"Settings", OnClick:"BrowseSettings", ShortDescriptionLine2:"Edit channel settings", HDPosterUrl:"pkg:/images/Settings.jpg", SDPosterUrl:"pkg:/images/Settings.jpg"})
    menudata.Push({ShortDescriptionLine1:"Search", OnClick:"SearchYoutube", ShortDescriptionLine2:"Search YouTube for videos",  HDPosterUrl:"pkg:/images/Search.jpg", SDPosterUrl:"pkg:/images/Search.jpg"})

    if (ytusername<>invalid) and (isnonemptystr(ytusername)) then
        menudata.Push({ShortDescriptionLine1:"What to Watch", FeedURL:"users/" + ytusername + "/newsubscriptionvideos?v=2&max-results=50", Category:"false", ShortDescriptionLine2:"What's new to watch", HDPosterUrl:"pkg:/images/whattowatch.jpg", SDPosterUrl:"pkg:/images/whattowatch.jpg"})
        menudata.Push({ShortDescriptionLine1:"My Playlists", FeedURL:"users/" + ytusername + "/playlists?v=2&max-results=50", Category:"true", ShortDescriptionLine2:"Browse your Playlists", HDPosterUrl:"pkg:/images/YourPlaylists.jpg", SDPosterUrl:"pkg:/images/YourPlaylists.jpg"})
        menudata.Push({ShortDescriptionLine1:"My Subscriptions", FeedURL:"users/" + ytusername + "/subscriptions?v=2&max-results=50", Category:"true", ShortDescriptionLine2:"Browse your Subscriptions", HDPosterUrl:"pkg:/images/YourSubscriptions.jpg", SDPosterUrl:"pkg:/images/YourSubscriptions.jpg"})
        menudata.Push({ShortDescriptionLine1:"My Favorites", FeedURL:"users/" + ytusername + "/favorites?v=2&max-results=50", Category:"false", ShortDescriptionLine2:"Browse your favorite videos", HDPosterUrl:"pkg:/images/YourFavorites.jpg", SDPosterUrl:"pkg:/images/YourFavorites.jpg"})
    end if

    menudata.Push({ShortDescriptionLine1:"Nursery Rhymes", FeedURL:"pkg:/xml/nursery.xml", Category:"true",  ShortDescriptionLine2:"Collection of featured Nursery Rhymes", HDPosterUrl:"pkg:/images/NurseryRhymes.jpg", SDPosterUrl:"pkg:/images/NurseryRhymes.jpg"})
    menudata.Push({ShortDescriptionLine1:"Top Channels", FeedURL:"pkg:/xml/topchannels.xml", Category:"true",  ShortDescriptionLine2:"Top Channels", HDPosterUrl:"pkg:/images/TopChannels.jpg", SDPosterUrl:"pkg:/images/TopChannels.jpg"})
    menudata.Push({ShortDescriptionLine1:"Top Rated", FeedURL:"pkg:/xml/toprated.xml", Category:"true",  ShortDescriptionLine2:"Top Rated videos", HDPosterUrl:"pkg:/images/TopRated.jpg", SDPosterUrl:"pkg:/images/TopRated.jpg"})
    menudata.Push({ShortDescriptionLine1:"Most Discussed", FeedURL:"pkg:/xml/mostdiscussed.xml", Category:"true",  ShortDescriptionLine2:"Most Discussed videos", HDPosterUrl:"pkg:/images/MostDiscussed.jpg", SDPosterUrl:"pkg:/images/MostDiscussed.jpg"})
    menudata.Push({ShortDescriptionLine1:"Top Favorites", FeedURL:"pkg:/xml/topfav.xml", Category:"true",  ShortDescriptionLine2:"Top Favorites videos", HDPosterUrl:"pkg:/images/TopFavorites.jpg", SDPosterUrl:"pkg:/images/TopFavorites.jpg"})
    menudata.Push({ShortDescriptionLine1:"Most Responded", FeedURL:"pkg:/xml/mostresponded.xml", Category:"true",  ShortDescriptionLine2:"Most Responded videos", HDPosterUrl:"pkg:/images/MostResponded.jpg", SDPosterUrl:"pkg:/images/MostResponded.jpg"})

    onselect = [1, menudata, m.youtube,
        function(menu, youtube, set_idx)
            'PrintAny(0, "menu:", menu)
            if (menu[set_idx]["FeedURL"] <> invalid) then
                feedurl = menu[set_idx]["FeedURL"]
                youtube.FetchVideoList(feedurl,menu[set_idx]["ShortDescriptionLine1"], invalid, strtobool(menu[set_idx]["Category"]))
            else if (menu[set_idx]["OnClick"] <> invalid) then
                onclickevent = menu[set_idx]["OnClick"]
                youtube[onclickevent]()
            end if
        end function]

    uitkDoPosterMenu(menudata, screen, onselect)

    sleep(25)
End Sub

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
    theme.OverhangOffsetHD_Y = "35"
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_HD.png"

    app.SetTheme(theme)
End Sub



