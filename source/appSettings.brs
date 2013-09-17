
Sub youtube_browse_settings()
    screen=uitkPreShowPosterMenu("","Settings")
    settingmenu = [
        {ShortDescriptionLine1:"Add Account",  ShortDescriptionLine2:"Add your YouTube account", HDPosterUrl:"pkg:/images/icon_key.jpg", SDPosterUrl:"pkg:/images/icon_key.jpg"},
        {ShortDescriptionLine1:"About",       ShortDescriptionLine2:"About the channel",           HDPosterUrl:"pkg:/images/icon_barcode.jpg", SDPosterUrl:"pkg:/images/icon_barcode.jpg"},
    ]
    onselect = [0, m, "AddAccount","About"]

    uitkDoPosterMenu(settingmenu, screen, onselect)
End Sub

Sub youtube_delink()
    ans=ShowDialog2Buttons("Deactivate","'ove link to your YouTube account?","Confirm","Cancel")
    if (ans = 0) then
        oa = Oauth()
        oa.erase()
    end if
End Sub

Sub youtube_add_account()
    screen = CreateObject("roKeyboardScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetTitle("Youtube User Settings")

    ytusername = RegRead("YTUSERNAME1")
    if (ytusername <> invalid) then
        screen.SetText(ytusername)
    end if

     screen.SetDisplayText("Enter your Youtube User name (not email address)")
     screen.SetMaxLength(35)
     screen.AddButton(1, "finished")
     screen.AddButton(2, "help")
     screen.Show()

     while (true)
         msg = wait(0, screen.GetMessagePort())
         if (type(msg) = "roKeyboardScreenEvent") then
             if (msg.isScreenClosed()) then
                 return
             else if (msg.isButtonPressed()) then
                 if (msg.GetIndex() = 1) then
                     searchText = screen.GetText()
                     'http://gdata.youtube.com/feeds/api/users/dkjhsdkjds/playlists?v=2&max-results=50
                    plxml = GetFeedXML("http://gdata.youtube.com/feeds/api/users/" + searchText + "/playlists?v=2&max-results=50")
                    if (plxml = invalid) then
                        ShowDialog1Button("Error", searchText + " is not a valid Youtube User Id. Please go to http://utmostsolutions.github.io/myvideobuzz/ to find your youtube username.", "Ok")
                    else
                        RegWrite("YTUSERNAME1", searchText)
                         screen.Close()
                         ShowHomeScreen()
                         'showHomeScreen(CreateScreen("roPosterScreen","Welcome","","scale-to-fit", "appHomeScreen"))
                         return
                    end if
                  else
                    ShowDialog1Button("Help", "Go to http://utmostsolutions.github.io/myvideobuzz/ to find your youtube username.", "Ok")
                 end if
             end if
         end if
     end while
End Sub


Sub youtube_about()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("About the channel")
    screen.AddParagraph("The channel is an open source channel developed by Utmost Solutions, based on the Roku Youtube Channel by Jeston Tigchon. Source code of the channel can be found at http://utmostsolutions.github.io/myvideobuzz/.  This channel is not affiliated with Google or YouTube.")
    screen.AddParagraph("Version 5.0")
    screen.AddButton(1, "Back")
    screen.Show()

    while (true)
        msg = wait(0, screen.GetMessagePort())

        if (type(msg) = "roParagraphScreenEvent") then
            if (msg.isScreenClosed()) then
                'print "Screen closed"
                exit while
            else if (msg.isButtonPressed()) then
                'print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                exit while
            else
                'print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub


Function GetFeedXML(plurl As String) As Dynamic
        http = NewHttp(plurl)
        plrsp = http.GetToStringWithRetry()

        plxml=CreateObject("roXMLElement")
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