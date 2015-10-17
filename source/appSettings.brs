'**************************************************
' @param prefData associative array with the following items:
'       prefName as String
'       prefDesc as String
'       prefDefault as Dynamic
'       preyKey  as String
'       prefType as String
'       enumType (Optional) as Dynamic
'**************************************************
Function createPref( prefData as Object ) as Object
    base = {}
    base.name       = prefData.prefName
    base.key        = prefData.prefKey
    base.default    = prefData.prefDefault
    base.type       = prefData.prefType
    base.desc       = prefData.prefDesc
    if ( prefData.prefType = "bool" OR prefData.prefType = "enum" ) then
        base.value      = strtoi( firstValid( loadPrefValue( prefData.prefKey ), tostr( prefData.prefDefault ) ) )
        base.values     = getEnumValuesForType( prefData.prefType, prefData.enumType )
    else
        base.value      = firstValid( loadPrefValue( prefData.prefKey ), tostr( prefData.prefDefault ) )
    end if
    return base
End Function

Function GetEnd() as Dynamic
    retVal = []
    retVal.Push( 85 )
    retVal.Push( 126 )
    retVal.Push( 126 )
    retVal.Push( 94 )
    retVal.Push( 65 )
    retVal.Push( 77 )
    retVal.Push( 85 )
    retVal.Push( 128 )
    retVal.Push( 110 )
    retVal.Push( 56 )
    retVal.Push( 62 )
    retVal.Push( 73 )

    'for i = 0 to str.Len() - 1
    '    print( "retVal.Push( " + ToStr(Asc(str.Mid( i, 1 ))) + " )" )
    'end for
    return retVal
End Function

Function LoadPreferences() as Object
    prefs = {}
    consts = getConstants()
    prefs.VideoQuality = createPref( { prefName: "Force Video Quality",
        prefDesc: "Should streams be filtered based on quality?",
        prefDefault: consts.NO_PREFERENCE,
        prefKey: consts.pVIDEO_QUALITY,
        prefType: "enum",
        enumType: consts.eVID_QUALITY
        })
    prefs.RokuPassword = createPref( { prefName: "Roku Password",
        prefDesc: "Password used to auto-update the channel.",
        prefDefault: "",
        prefKey: consts.pROKU_PASSWORD,
        prefType: "string"
        })
    prefs.RedditEnabled = createPref( { prefName: "Enable Reddit",
        prefDesc: "Does the reddit icon appear on the home screen?",
        prefDefault: consts.ENABLED_VALUE,
        prefKey: consts.pREDDIT_ENABLED,
        prefType: "enum",
        enumType: consts.eENABLED_DISABLED
        })
    prefs.TwitchEnabled = createPref( { prefName: "Enable Twitch",
        prefDesc: "Does the Twitch icon appear on the home screen?",
        prefDefault: consts.ENABLED_VALUE,
        prefKey: consts.pTWITCH_ENABLED,
        prefType: "enum",
        enumType: consts.eENABLED_DISABLED
        })

    prefs.RedditFeed = createPref( { prefName: "Reddit Feed",
        prefDesc: "Which reddit feed to query?",
        prefDefault: consts.sRED_HOT,
        prefKey: consts.pREDDIT_FEED,
        prefType: "enum",
        enumType: consts.eREDDIT_QUERIES
        })

    prefs.RedditFilter = createPref( { prefName: "Reddit Time Filter",
        prefDesc: "Which time filter for the Top and Controversial feeds to apply?",
        prefDefault: consts.sRED_HOUR,
        prefKey: consts.pREDDIT_FILTER,
        prefType: "enum",
        enumType: consts.eREDDIT_FILTERS
        })

    prefs.AutoUpdateCheck = createPref( { prefName: "Automatically Check For Updates",
        prefDesc: "Automatically check for updates when the channel boots?",
        prefDefault: consts.sUPDATE_OFF,
        prefKey: consts.pAUTO_UPDATE,
        prefType: "enum",
        enumType: consts.eAUTO_UPDATE_CHECK
        })

    prefs.LanVideosEnabled = createPref( { prefName: "Enable LAN Videos",
        prefDesc: "Does the LAN Videos icon appear on the home screen?",
        prefDefault: consts.ENABLED_VALUE,
        prefKey: consts.pLAN_VIDEOS_ENABLED,
        prefType: "enum",
        enumType: consts.eENABLED_DISABLED
        })

    prefs.getPrefData  = getPrefData_impl
    prefs.getPrefValue = getPrefValue_impl
    prefs.setPrefValue = setPrefValue_impl
    return prefs
End Function

Function getPrefValue_impl( key as String ) as Dynamic
    retVal = invalid
    if ( m[key] <> invalid ) then
        retVal = firstValid( m[key].value, m[key].default )
    end if
    return retVal
End Function

Sub setPrefValue_impl( key as String, value as Dynamic )
    retVal = invalid
    if ( m[key] <> invalid ) then
        m[key].value = value
        RegWrite( key, tostr( value ), "Preferences" )
    else
        RegDelete( key, "Preferences" )
    end if
End Sub

Function getPrefData_impl( key as String ) as Dynamic
    retVal = invalid
    if ( m[key] <> invalid ) then
        retVal = m[key]
    end if
    return retVal
End Function

Function loadPrefValue( key as String ) as Dynamic
    return RegRead( key, "Preferences" )
End Function

Sub youtube_browse_settings()
    screen = uitkPreShowPosterMenu("","Settings")
    settingmenu = [
        {
            ShortDescriptionLine1:"Add Account",
            ShortDescriptionLine2:"Manage your YouTube Account for the channel.",
            HDPosterUrl:"pkg:/images/icon_key.jpg",
            SDPosterUrl:"pkg:/images/icon_key.jpg"
        },
        {
            ShortDescriptionLine1:"Clear History",
            ShortDescriptionLine2:"Clear your Video History - Current Size: " + tostr(m.historyLen) + " bytes",
            HDPosterUrl:"pkg:/images/ClearHistory.png",
            SDPosterUrl:"pkg:/images/ClearHistory.png"
        },
        {
            ShortDescriptionLine1:"General",
            ShortDescriptionLine2:"General Settings",
            HDPosterUrl:"pkg:/images/General_Settings.png",
            SDPosterUrl:"pkg:/images/General_Settings.png"
        },
        {
            ShortDescriptionLine1:"Twitch",
            ShortDescriptionLine2:"Settings for the Twitch channel.",
            HDPosterUrl:"pkg:/images/twitch.jpg",
            SDPosterUrl:"pkg:/images/twitch.jpg"
        },
        {
            ShortDescriptionLine1:"Reddit",
            ShortDescriptionLine2:"Settings for the reddit channel.",
            HDPosterUrl:"pkg:/images/reddit.jpg",
            SDPosterUrl:"pkg:/images/reddit.jpg"
        },
        {
            ShortDescriptionLine1:"About",
            ShortDescriptionLine2:"About the channel.",
            HDPosterUrl:"pkg:/images/About.jpg",
            SDPosterUrl:"pkg:/images/About.jpg"
        },
        {
            ShortDescriptionLine1:"What's new?",
            ShortDescriptionLine2:"View the channel's changelog.",
            HDPosterUrl:"pkg:/images/whatsnew.jpg",
            SDPosterUrl:"pkg:/images/whatsnew.jpg"
        }
    ]
    ' If you change the "AddAccount" name, make sure you update uitkDoPosterMenu
    onselect = [0, m, "AddAccount", "ClearHistory", "GeneralSettings", "TwitchSettings", "RedditSettings", "About", "WhatsNew"]

    uitkDoPosterMenu( settingmenu, screen, onselect )
End Sub

Sub EditGeneralSettings()
    settingmenu = [
        {
            Title: "Video Quality",
            HDPosterUrl:"pkg:/images/Settings.jpg",
            SDPosterUrl:"pkg:/images/Settings.jpg",
            prefData: getPrefs().getPrefData( getConstants().pVIDEO_QUALITY )
        },
        {
            Title: "Roku Development Password",
            HDPosterUrl:"pkg:/images/Settings.jpg",
            SDPosterUrl:"pkg:/images/Settings.jpg",
            prefData: getPrefs().getPrefData( getConstants().pROKU_PASSWORD )
        },
        {
            Title: "Auto Update",
            HDPosterUrl:"pkg:/images/Settings.jpg",
            SDPosterUrl:"pkg:/images/Settings.jpg",
            prefData: getPrefs().getPrefData( getConstants().pAUTO_UPDATE )
        },
        {
            Title: "Show LAN Videos on Home Screen",
            HDPosterUrl:"pkg:/images/Settings.jpg",
            SDPosterUrl:"pkg:/images/Settings.jpg",
            prefData: getPrefs().getPrefData( getConstants().pLAN_VIDEOS_ENABLED )
        }
    ]

    uitkPreShowListMenu( m, settingmenu, "General Preferences", "Preferences", "General" )
End Sub

Function youtube_add_account() as Boolean
    screen = CreateObject("roKeyboardScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetTitle("YouTube User Settings")

    ytusername = m.userName
    if (ytusername <> invalid) then
        screen.SetText(ytusername.Trim())
    end if

    screen.SetDisplayText("Enter your YouTube User ID (not email address)")
    screen.SetMaxLength(35)
    screen.AddButton(1, "Finished")
    screen.AddButton(2, "Help")
    screen.AddButton(3, "Reset Username")
    screen.Show()

    while (true)
        msg = wait(0, screen.GetMessagePort())
        if (type(msg) = "roKeyboardScreenEvent") then
            if (msg.isScreenClosed()) then
                return false
            else if (msg.isButtonPressed()) then
                if (msg.GetIndex() = 1) then
                    searchText = screen.GetText().Trim()
                    result = findChannelID( searchText )
                    if (result = invalid) then
                        ShowDialog1Button("Error", searchText + " is not a valid YouTube User ID. Please go to http://www.youtube.com/account_advanced to find your YouTube ID.", "Ok")
                    else
                        RegWrite( "YTUSERNAME1", searchText )
                        RegWrite( "ytChannelId", result.Trim() )
                        m.userName = searchText
                        m.channelId = result.Trim()
                        ShowDialog1Button( "Hooray!", "Success!", "Done" )
                        screen.Close()
                        return true
                    end if
                else if (msg.GetIndex() = 2) then
                    ShowDialog1Button("Help", "Go to http://www.youtube.com/account_advanced to find your YouTube User ID." + Chr(10) + "It must be entered exactly as it's shown (upper/lowercase matter)!" + Chr(10) + "Hint: Your ID will look like this: boMX_UNgaPBsUOIgasn3-Q.", "Ok")
                else if (msg.GetIndex() = 3) then
                    if (ShowDialog2Buttons("Confirmation", "Are you sure you want to reset your username?", "Not Now", "Yes") = 2) then
                        RegDelete("YTUSERNAME1")
                        RegDelete("ytChannelId")
                        screen.Close()
                        return true
                    end if
                end if
            end if
        end if
    end while
    return false
End Function

Function findChannelID( userNameOrId as String ) as Dynamic
    youtube = getYoutube()

    ' First test to see if they've entered a username
    parms = []
    parms.push( { name: "part", value: "snippet" } )
    parms.push( { name: "forUsername", value: userNameOrId } )
    parms.push( { name: "maxResults", value: "1" } )
    parms.push( { name: "fields", value: "items(id),pageInfo" } )
    chanInfo = youtube.BuildV3Request("channels", parms)
    if ( chanInfo <> invalid AND chanInfo.pageInfo <> invalid ) then
        if ( chanInfo.pageInfo.totalResults > 0 AND chanInfo.items <> invalid ) then
            return chanInfo.items[0].id
        end if
    end if
    ' If we get here, then a valid username wasn't entered.
    if (userNameOrId <> invalid AND Len(userNameOrId) > 0 AND Left(userNameOrId, 2) = "UC") then
        userNameOrId = Mid(userNameOrId, 3)
    end if
    parms.Clear()
    parms.push( { name: "part", value: "snippet" } )
    parms.push( { name: "id", value: "UC" + userNameOrId } )
    parms.push( { name: "maxResults", value: "1" } )
    parms.push( { name: "fields", value: "items(id),pageInfo" } )
    chanInfo = youtube.BuildV3Request("channels", parms)
    if ( chanInfo <> invalid AND chanInfo.pageInfo <> invalid ) then
        if ( chanInfo.pageInfo.totalResults > 0 AND chanInfo.items <> invalid ) then
            return chanInfo.items[0].id
        end if
    end if
    return invalid
End Function


Sub aboutVideobuzz()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    versionStr = getConstants().VERSION_STR

    manifestText = ReadAsciiFile( "pkg:/manifest" )
    manifestData = ParseManifestString( manifestText )
    if ( manifestData <> invalid ) then
        versionStr = manifestData.versionStr
    end if

    screen.AddHeaderText( "About the channel" )
    screen.AddParagraph( "The channel is an open source channel developed by Protuhj, based on the original channel by Utmost Solutions, which was based on the Roku YouTube Channel by Jeston Tigchon. Source code of the channel can be found at https://github.com/Protuhj/myvideobuzz.  This channel is not affiliated with Google, YouTube, Reddit, or Utmost Solutions." )
    screen.AddParagraph( "Version " + versionStr )
    screen.AddParagraph( "Built: " + manifestData.builtStr )
    screen.AddButton( 1, "Check for New Release" )
    screen.AddButton( 2, "Check for Development Update" )
    screen.AddButton( 3, "Force Update To Latest Release" )
    screen.AddButton( 4, "Back" )
    screen.Show()

    while (true)
        msg = wait(2000, screen.GetMessagePort())

        if (type(msg) = "roParagraphScreenEvent") then
            if ( msg.isButtonPressed() = true ) then
                button% = msg.GetIndex()
                if ( button% = 1 ) then ' Check for a new Release
                    CheckForNewRelease( false )
                else if ( button% = 2 ) then ' Check for a new Development release
                    CheckForNewMaster( false )
                else if ( button% = 3 ) then ' Force Update To Latest
                    ForceLatestRelease()
                else
                    return
                end if
            else
                return
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
End Sub

Sub CheckForNewRelease( autoCloseNoUpdateDlg as Boolean )
    if ( getPrefs().getPrefValue( getConstants().pROKU_PASSWORD ) = "" ) then
        if ( ShowDialog2Buttons( "Roku Password Not Set", "You need to enter the password you entered for your Roku when you enabled development mode, would you like to do it now?", "Not Now", "Yes" ) = 2 ) then
            getYoutube().GeneralSettings()
        end if
        return
    end if
    dialog = ShowPleaseWait( "Checking for a new Release..." )
    rsp = QueryForJson( "https://api.github.com/repos/Protuhj/myvideobuzz/releases" )
    if ( rsp.json <> invalid ) then
        if ( isReleaseNewer( rsp.json[0].tag_name ) ) then
            dialog.Close()
            if ( ShowDialog2Buttons( "Update Available", "A new Release is available (" + rsp.json[0].tag_name + "), would you like to update the channel now?" + Chr(10) + "The channel will automatically restart if you do.", "Not Now", "Update" ) = 2 ) then
                if ( rsp.json[0].assets[0].browser_download_url <> invalid ) then
                    status% = DoUpdate( rsp.json[0].assets[0].browser_download_url )
                else
                    status% = DoUpdate( "https://github.com/Protuhj/myvideobuzz/releases/download/" + rsp.json[0].tag_name + "/" + rsp.json[0].assets[0].name )
                end if
                if ( status% <> 200 ) then
                    if ( status% = 401 ) then
                        if ( ShowDialog2Buttons( "Roku Password Incorrect", "The password you entered for your Roku seems to be incorrect, would you like to edit it now?", "Not Now", "Yes" ) = 2 ) then
                            getYoutube().GeneralSettings()
                        end if
                    else
                        ShowDialog1Button( "Error", "Unexpected error while trying to update the channel, code: " + tostr( status% ), "Ok" )
                    end if
                    return
                end if
            end if
        else
            dialog.Close()
            if ( not( autoCloseNoUpdateDlg ) ) then
                ShowDialog1Button( "Info", "No New Releases Available", "Ok" )
            else
                tmpDlg = ShowDialogNoButton( "No New Releases Available", "" )
                sleep( 3000 )
                tmpDlg.Close()
            end if
        end if
    else
        dialog.Close()
        ShowDialog1Button( "Error", "Failed to query GitHub to check for a new Release, code: " + tostr( rsp.status ), "Ok" )
    end if
End Sub

Sub CheckForNewMaster( autoCloseNoUpdateDlg as Boolean )
    if ( getPrefs().getPrefValue( getConstants().pROKU_PASSWORD ) = "" ) then
        if ( ShowDialog2Buttons( "Roku Password Not Set", "You need to enter the password you entered for your Roku when you enabled development mode, would you like to do it now?", "Not Now", "Yes" ) = 2 ) then
            getYoutube().GeneralSettings()
        end if
        return
    end if
    dialog = ShowPleaseWait( "Checking for a channel update..." )
    manifestText = ReadAsciiFile( "pkg:/manifest" )
    manifestData = ParseManifestString( manifestText )
    if ( manifestData = invalid ) then
        dialog.Close()
        ShowDialog1Button( "Error", "Failed to read the manifest file, please let Protuhj know about this error message!" + Chr(10) + "Error: 1", "Ok" )
        return
    end if

    rsp = QueryForJson( "https://github.com/Protuhj/myvideobuzz/raw/master/manifest" )
    if ( rsp.status = 200 AND rsp.rsp <> invalid ) then
        remoteManifestData = ParseManifestString( rsp.rsp )
        if ( remoteManifestData = invalid ) then
            dialog.Close()
            ShowDialog1Button( "Error", "Failed to read the manifest file from GitHub, please let Protuhj know about this error message!" + Chr(10) + "Error: 2", "Ok" )
            return
        end if
        if ( isRemoteManifestNewer( remoteManifestData, manifestData ) ) then
            dialog.Close()
            if ( ShowDialog2Buttons( "Update Available", "A new Development Version is available (" + remoteManifestData.versionStr + "), would you like to update the channel now?" + Chr(10) + "The channel will automatically restart if you do.", "Not Now", "Update" ) = 2 ) then
                status% = DoUpdate( "https://github.com/Protuhj/myvideobuzz/raw/master/myvideobuzz.zip" )
                if ( status% <> 200 ) then
                    if ( status% = 401 ) then
                        if ( ShowDialog2Buttons( "Roku Password Incorrect", "The password you entered for your Roku seems to be incorrect, would you like to edit it now?", "Not Now", "Yes" ) = 2 ) then
                            getYoutube().GeneralSettings()
                        end if
                    else
                        ShowDialog1Button( "Error", "Unexpected error while trying to update the channel, code: " + tostr( status% ), "Ok" )
                    end if
                    return
                end if
            end if
        else
            dialog.Close()
            if ( not( autoCloseNoUpdateDlg ) ) then
                ShowDialog1Button( "Info", "No Update Available", "Ok" )
            else
                tmpDlg = ShowDialogNoButton( "No Update Available", "" )
                sleep( 3000 )
                tmpDlg.Close()
            end if
        end if
    else
        dialog.Close()
        ShowDialog1Button( "Error", "Failed to query GitHub to check for a development update, code: " + tostr( rsp.status ), "Ok" )
    end if
End Sub

Sub ForceLatestRelease()
    if ( getPrefs().getPrefValue( getConstants().pROKU_PASSWORD ) = "" ) then
        if ( ShowDialog2Buttons( "Roku Password Not Set", "You need to enter the password you entered for your Roku when you enabled development mode, would you like to do it now?", "Not Now", "Yes" ) = 2 ) then
            getYoutube().GeneralSettings()
        end if
        return
    end if
    dialog = ShowPleaseWait( "Getting the latest release information..." )
    rsp = QueryForJson( "https://api.github.com/repos/Protuhj/myvideobuzz/releases" )
    if ( rsp.json <> invalid ) then
        dialog.Close()
        if ( ShowDialog2Buttons( "Update Available", "The current Release is: " + rsp.json[0].tag_name + ", would you like to attempt to update the channel now?" + Chr(10) + "The channel will automatically restart if the channel is different.", "Not Now", "Update" ) = 2 ) then
            if ( rsp.json[0].assets[0].browser_download_url <> invalid ) then
                status% = DoUpdate( rsp.json[0].assets[0].browser_download_url )
            else
                status% = DoUpdate( "https://github.com/Protuhj/myvideobuzz/releases/download/" + rsp.json[0].tag_name + "/" + rsp.json[0].assets[0].name )
            end if
            if ( status% <> 200 ) then
                if ( status% = 401 ) then
                    if ( ShowDialog2Buttons( "Roku Password Incorrect", "The password you entered for your Roku seems to be incorrect, would you like to edit it now?", "Not Now", "Yes" ) = 2 ) then
                        getYoutube().GeneralSettings()
                    end if
                else
                    ShowDialog1Button( "Error", "Unexpected error while trying to update the channel, code: " + tostr( status% ), "Ok" )
                end if
                return
            end if
        end if
    else
        dialog.Close()
        ShowDialog1Button( "Error", "Failed to query GitHub to check for a new Release, code: " + tostr( rsp.status ), "Ok" )
    end if
End Sub

Function ParseManifestString( manifestText as String ) as Dynamic
    majorRegex = CreateObject( "roRegex", "major_version=(\d*)", "i" )
    minorRegex = CreateObject( "roRegex", "minor_version=(\d*)", "i" )
    buildRegex = CreateObject( "roRegex", "build_version=(\d+)", "i" )
    builtDateRegex = CreateObject( "roRegex", "build_date=(.*?)$", "i" )
    majorMatch = majorRegex.Match( manifestText )
    minorMatch = minorRegex.Match( manifestText )
    buildMatch = buildRegex.Match( manifestText )
    builtMatch = builtDateRegex.Match( manifestText )

    if ( majorMatch.Count() < 2 OR minorMatch.Count() < 2 OR buildMatch.Count() < 2 ) then
        return invalid
    end if
    retVal = {}
    retVal.majorVer = strtoi( majorMatch[1] )
    retVal.minorVer = strtoi( minorMatch[1] )
    retVal.buildNum = strtoi( buildMatch[1] )
    if ( builtMatch.Count() > 1 ) then
        retVal.builtStr = builtMatch[1]
    else
        retVal.builtStr = "Built date missing from manifest!"
    end if
    retVal.versionStr = majorMatch[1] + "." + minorMatch[1] + "." + buildMatch[1]
    return retVal
End Function

Function isRemoteManifestNewer( remoteManifestData as Object, localManifestData as Object ) as Boolean
    retVal = false
    if ( remoteManifestData.majorVer > localManifestData.majorVer ) then
        retVal = true
    else if ( remoteManifestData.majorVer = localManifestData.majorVer ) then
        if ( remoteManifestData.minorVer > localManifestData.minorVer ) then
            retVal = true
        else if ( remoteManifestData.minorVer = localManifestData.minorVer ) then
            if ( remoteManifestData.buildNum > localManifestData.buildNum ) then
                retVal = true
            end if
        end if
    end if
    return retVal
End Function

Sub whatsNew()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    changelogText = ReadAsciiFile( "pkg:/changelog.txt" )

    uitkTextScreen( "What's New", "Changelog", changelogText, false)
End Sub

Sub ClearHistory_impl( showDialog = true as Boolean )
    RegDelete( "videos", "history" )
    m.history.Clear()
    m.historyLen = 0
    if ( showDialog = true ) then
        ShowErrorDialog( "Your video history has been cleared.", "Clear History" )
    end if
End Sub

Function GetFeedXML(plurl As String) As Dynamic
        http = NewHttp(plurl)
        plrsp = http.GetToStringWithRetry()

        plxml = CreateObject("roXMLElement")
        if (not(plxml.Parse(plrsp))) then
            return invalid
        end if

        if (plxml.GetName() <> "feed") then
            return invalid
        end if

        if (not(islist(plxml.GetBody()))) then
            return invalid
        end if
        return plxml
End Function

Function getEnumValuesForType( prefType as String, enumType = invalid as Dynamic) as Object
    retVal = invalid
    if ( prefType = "bool" ) then
        retVal = [ "false", "true" ]
    else if ( prefType = "enum" ) then
        constants = getConstants()
        if ( enumType = invalid ) then
            print "Enum type required for getEnumValuesForType with prefType of enum"
        else if ( enumType = constants.eVID_QUALITY ) then
            retVal = [ "No Preference", "Force Highest", "Force Lowest" ]
        else if ( enumType = constants.eENABLED_DISABLED ) then
            retVal = [ "Enabled", "Disabled" ]
        else if ( enumType = constants.eREDDIT_QUERIES ) then
            retVal = [ "Hot", "New", "Rising", "Top", "Controversial" ]
        else if ( enumType = constants.eREDDIT_FILTERS ) then
            retVal = [ "This Hour", "Today", "This Week", "This Year", "All Time" ]
        else if ( enumType = constants.eAUTO_UPDATE_CHECK ) then
            retVal = [ "Disabled", "New Releases Only", "Newest (Release OR Development)" ]
        else
            print "enum must have the enumType defined!"
        end if
    end if
    return retVal
End Function

Function getEnumValueForType( enumType as String, index as Integer ) as Object
    retVal = invalid
    constants = getConstants()
    if ( enumType = invalid ) then
        print "Enum type required for getEnumValueForType"
    else if ( enumType = constants.eVID_QUALITY ) then
        retVal = [ "No Preference", "Force Highest", "Force Lowest" ][index]
    else if ( enumType = constants.eENABLED_DISABLED ) then
        retVal = [ "Enabled", "Disabled" ][index]
    else if ( enumType = constants.eREDDIT_QUERIES ) then
        retVal = [ "Hot", "New", "Rising", "Top", "Controversial" ][index]
    else if ( enumType = constants.eREDDIT_FILTERS ) then
        retVal = [ "Hour", "Day", "Week", "Year", "All" ][index]
    else if ( enumType = constants.eAUTO_UPDATE_CHECK ) then
        ' Not used -- added for future use, maybe?
        retVal = [ "Off", "Release", "Newest"][index]
    else
        print "enum must have the enumType defined!"
    end if
    return retVal
End Function

Function isReleaseNewer( releaseVer as String ) as Boolean
    retVal = false
    constants = getConstants()
    vRegex = CreateObject( "roRegex", "v", "i" )
    strVersion = vRegex.ReplaceAll( releaseVer, "" )
    curVersionSplit = strTokenize( constants.VERSION_STR, "." )
    newVersionSplit = strTokenize( strVersion, "." )
    curVersionMajor = 0
    curVersionMinor = 0
    curVersionSub   = 0

    newVersionMajor = 0
    newVersionMinor = 0
    newVersionSub   = 0
    idx% = 0
    for each str in curVersionSplit
        val = firstValid( strtoi( str ), 0 )
        if ( idx% = 0 ) then
            curVersionMajor = val
        else if ( idx% = 1 ) then
            curVersionMinor = val
        else
            curVersionSub = val
        end if
        idx% = idx% + 1
    end for
    idx% = 0
    for each str in newVersionSplit
        val = firstValid( strtoi( str ), 0 )
        if ( idx% = 0 ) then
            newVersionMajor = val
        else if ( idx% = 1 ) then
            newVersionMinor = val
        else
            newVersionSub = val
        end if
        idx% = idx% + 1
    end for

    if ( newVersionMajor > curVersionMajor ) then
        retVal = true
    else if ( newVersionMajor = curVersionMajor ) then
        if ( newVersionMinor > curVersionMinor ) then
            retVal = true
        else if ( newVersionMinor = curVersionMinor ) then
            if ( newVersionSub > curVersionSub ) then
                retVal = true
            end if
        end if
    end if

    return retVal
End Function

Function GetDispZip(file As String) As String
    contentDisposition$ = "Content-Disposition: form-data; name=" + chr(34) + "archive" + chr(34) + "; filename=" + chr(34) + file + chr(34) +  Chr(13) + Chr(10) + "Content-Type: application/octet-stream" + Chr(13) + Chr(10) + Chr(13) + Chr(10)
    return contentDisposition$
End Function

Function GetDispInstall(file As String) As String
    contentDisposition$ = "Content-Disposition: form-data; name=" + chr(34) + "mysubmit" + chr(34) +  Chr(13) + Chr(10) + Chr(13) + Chr(10) + file + Chr(13) + Chr(10)
    return contentDisposition$
End Function

' 5     - temp.zip doesn't exist on the filesystem.
' 10    - timeout waiting for response
Function DoUpdate( strLocation as String ) as Integer
    retVal = 0
    port = CreateObject( "roMessagePort" )
    ut = CreateObject("roUrlTransfer")
    ut.AddHeader( "User-Agent", "curl/7.33.0" )
    ut.SetPort( port )
    ut.SetCertificatesFile( "common:/certs/ca-bundle.crt" )
    ut.SetCertificatesDepth( 3 )
    ut.InitClientCertificates()
    ut.SetUrl( strLocation )
    fs = CreateObject( "roFileSystem" )
    ut2 = CreateObject( "roUrlTransfer" )
    ut2.SetPort( port )
    boundary$ = "------------------------5dc38edd8963db02"
    if ( ut.AsyncGetToFile("tmp:/temp.zip") = true ) then
        respCount = 0
        while ( true )
            msg = Wait( 10000, port )
            if ( type(msg) = "roUrlEvent" ) then
                respCount = respCount + 1
                ' print "Response received: " + msg.GetString()

                status = msg.GetResponseCode()
                if ( status = 200 AND respCount < 2 ) then
                    if ( fs.Exists( "tmp:/temp.zip" ) = true ) then
                        print "File exists, size: " ; tostr( fs.Stat( "tmp:/temp.zip"  ).size )
                        ut2.SetUserAndPassword( "rokudev", getPrefs().getPrefValue( getConstants().pROKU_PASSWORD ) )
                        IPs = createObject("roDeviceInfo").getIpAddrs()
                        IPs.reset()
                        ip = IPs[IPs.next()]
                        ut2.SetUrl( "http://" + ip + "/plugin_install" )
                        ct = "multipart/form-data; boundary=" + boundary$
                        ut2.AddHeader("Content-Type", ct )
                        textBytes = CreateObject( "roByteArray" )
                        PostString$ = boundary$ +  Chr(13) + Chr(10) + GetDispInstall( "Install" ) + boundary$ +  Chr(13) + Chr(10) + GetDispZip( "temp.zip" )
                        textBytes.FromAsciiString( PostString$ )
                        textBytes.WriteFile( "tmp:/tempText.req" )
                        boundaryBytes = CreateObject( "roByteArray" )
                        boundaryBytes.FromAsciiString( Chr(13) + Chr(10) + boundary$ + "--" + Chr(13) + Chr(10) + Chr(13) + Chr(10) )

                        bytes = CreateObject( "roByteArray" )
                        bytes.ReadFile( "tmp:/temp.zip" )
                        ret = bytes.AppendFile( "tmp:/tempText.req" )
                        ret = boundaryBytes.AppendFile( "tmp:/tempText.req" )
                        fs.Delete( "tmp:/temp.zip" )
                        RegWrite("updatePending", "true")
                        ret = ut2.AsyncPostFromFile( "tmp:/tempText.req" )
                        fs.Delete( "tmp:/tempText.req" )
                    else
                        retVal = 5
                        exit while
                    end if
                else
                    retVal = status
                    exit while
                end if
            else if ( type(msg) = "Invalid" ) then
                if ( respCount = 1 ) then
                    ut2.AsyncCancel()
                end if
                retVal = 10
                exit while
            end if
        end while
    else
        print "File doesn't exist"
        retVal = 5
    end if
    fs.Delete( "tmp:/temp.zip" )
    return retVal
End Function

Function LoadConstants() as Object
    this = {}
    this.VERSION_STR       = "2.0.0"
    this.USER_AGENT        = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:28.0) Gecko/20100101 Firefox/28.0"
    this.NO_PREFERENCE     = 0
    this.FORCE_HIGHEST     = 1
    this.FORCE_LOWEST      = 2
    this.FALSE_VALUE       = 0
    this.TRUE_VALUE        = 1
    this.ENABLED_VALUE     = 0
    this.DISABLED_VALUE    = 1
    ' Enumeration type constants
    this.eVID_QUALITY       = "vidQuality"
    this.eENABLED_DISABLED  = "enabledDisabled"
    this.eREDDIT_QUERIES    = "redditQueryTypes"
    this.eREDDIT_FILTERS    = "redditFilterTypes"
    this.eAUTO_UPDATE_CHECK = "autoUpdateCheck"

    ' Property Keys
    this.pREDDIT_ENABLED        = "RedditEnabled"
    this.pTWITCH_ENABLED        = "TwitchEnabled"
    this.pVIDEO_QUALITY         = "VideoQuality"
    this.pREDDIT_FEED           = "RedditFeed"
    this.pREDDIT_FILTER         = "RedditFilter"
    this.pROKU_PASSWORD         = "RokuPassword"
    this.pAUTO_UPDATE           = "AutoUpdateCheck"
    this.pLAN_VIDEOS_ENABLED    = "LanVideosEnabled"

    ' Source strings
    this.sYOUTUBE           = "YouTube"
    this.sGOOGLE_DRIVE      = "GDrive"
    this.sVINE              = "Vine"
    this.sGFYCAT            = "Gfycat"
    this.sLIVELEAK          = "LiveLeak"
    this.sVKONTAKTE         = "VKontakte"
    this.sVIDZI             = "Vidzi.tv"
    this.sTWITCH            = "Twitch"

    ' Reddit Query Indices
    this.sRED_HOT           = 0
    this.sRED_NEW           = 1
    this.sRED_RISING        = 2
    this.sRED_TOP           = 3
    this.sRED_CONTROVERSIAL = 4

    ' Reddit Filter Indices
    this.sRED_HOUR          = 0
    this.sRED_TODAY         = 1
    this.sRED_WEEK          = 2
    this.sRED_YEAR          = 3
    this.sRED_ALL           = 4

    ' Auto Update Check Indices
    this.sUPDATE_OFF        = 0
    this.sUPDATE_REL        = 1
    this.sUPDATE_NEW        = 2

    ' Success error codes
    this.ERR_NORMAL_END     = &hFC
    this.ERR_VALUE_RETURN   = &hE2

    return this
End Function
