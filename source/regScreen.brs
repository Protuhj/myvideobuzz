
Function doRegistration() As Integer

    screenFacade = CreateObject("roParagraphScreen")
    screenFacade.show()

    oa = Oauth()

    if (oa.linked()) then
        token_status = checkOauthToken()
        if (token_status = 1) then
            oa.erase()
        else if (token_status = 2) then
            return token_status
        end if
    end if

    if (not(oa.linked())) then
        status = doOauthLink()
        if (status <> 0) then
            return status
        end if
        showCongratulationsScreen()
    end if

    return 0

End Function

Function checkOauthToken() As Integer
    print "RegScreen: checkOauthToken"

    youtube = LoadYouTube()
    oa = Oauth()

    http = NewHttp(youtube.oauth_prefix+"/AuthSubTokenInfo")
    oa.sign(http,true)
    http.getToStringWithTimeout(10)
    if (http.status = 200) then
        return 0
    else
        ans=ShowDialog2Buttons("Token invalid", "Unable to authenticate.  This could be a temporary issue or due to revoked access by the user.", "Link Again", "Exit")
        if (ans = 0) then
            return 1
        else
            return 2
        end if
    end if
End Function

Function doOauthLink() As Integer
    status = doTempLink()
    if (status = 0)
        status = doYouTubeEnroll()
        if (status = 0) then
            status = doLink()
        end if
    end if

    return status
End Function

Function doTempLink() As Integer
    print "RegScreen: doTempLink"
    status = 2

    youtube = LoadYouTube()
    oa = Oauth()

    http = NewHttp(youtube.oauth_prefix+"/OAuthGetRequestToken")
    http.AddParam("scope",youtube.scope)
    http.AddParam("oauth_callback",youtube.link_prefix+"/oauth/callback")
    oa.sign(http,false)
    rsp = http.getToStringWithTimeout(10)

    print "RegScreen: http failure = "; http.Http.GetFailureReason()
    print "RegScreen: temporary registration response = "; rsp

    'temporary token
    params = NewUrlParams(rsp)
    oa.authtoken = params.get("oauth_token")
    oa.authsecret = params.get("oauth_token_secret")

    if (isnonemptystr(oa.authtoken) AND isnonemptystr(oa.authsecret)) then
        print "temp oauth: "; oa.dump()
        status = 0
    else
        print "RegScreen: failed to retrieve temporary token"
        print "temp oauth: "; oa.dump()
        status = 2
    end if

    return status
End Function

Function doYouTubeEnroll() As Integer
    print "RegScreen: doYouTubeEnroll"
    status = 1 ' error

    youtube = LoadYouTube()
    oa = Oauth()

    regscreen = displayRegistrationScreen()

    while (true)
        sn = CreateObject("roDeviceInfo").GetDeviceUniqueId()
        regCode = getRegistrationCode(sn)

        'if we've failed to get the registration code, bail out, otherwise we'll
        'get rid of the retreiving... text and replace it with the real code
        if (regCode = "") then
            return 2
        end if
        regscreen.SetRegistrationCode(regCode)
        print "Enter registration code " + regCode + " at " + youtube.link_prefix + " for " + sn

        duration = 0
        'make an http request to see if the device has been registered on the backend
        while (true)
            status = checkRegistrationStatus(sn, regCode)
            print itostr(status)
            if (status < 3) then
                return status
            end if

            getNewCode = false
            retryInterval=m.retryInterval
            retryDuration=m.retryDuration
            print "retry duration "; itostr(duration); " at ";  itostr(retryInterval);
            print " sec intervals for "; itostr(retryDuration); " secs max"

            'wait for the retry interval to expire or the user to press a button
            'indicating they either want to quit or fetch a new registration code
            while (true)
                print "Wait for " + itostr(retryInterval)
                msg = wait(retryInterval * 1000, regscreen.GetMessagePort())
                duration = duration + retryInterval
                if (msg = invalid) then
                    exit while
                end if

                if (type(msg) = "roCodeRegistrationScreenEvent") then
                    if (msg.isScreenClosed()) then
                        print "Screen closed"
                        return 1
                    else if (msg.isButtonPressed()) then
                        print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                        if (msg.GetIndex() = 0) then
                            regscreen.SetRegistrationCode("retrieving code...")
                            getNewCode = true
                            exit while
                        end if
                        if (msg.GetIndex() = 1) then
                            return 1
                        end if
                    end if
                end if
            end while

            if (duration >= retryDuration) then
                ans = ShowDialog2Buttons("Request timed out", "Unable to link to YouTube within time limit.", "Try Again", "Back")
                if (ans = 0) then
                    regscreen.SetRegistrationCode("retrieving code...")
                    getNewCode = true
                else
                    return 1
                end if
            end if

            if (getNewCode) then
                exit while
            end if

            print "poll prelink again..."
        end while
    end while

    print "RegScreen: enroll status: "; status
    return status
End Function

Function doLink() As Integer
    print "RegScreen: doLink"
    status = 2

    youtube = LoadYouTube()
    oa = Oauth()

    http = NewHttp(youtube.oauth_prefix+"/OAuthGetAccessToken")
    'oa.verifier = pinCode
    oa.sign(http,true,true)
    print "RegScreen: access_token URL: "; http.GetUrl()

    rsp = http.getToStringWithTimeout(10)
    print "RegScreen: final registration response = "; rsp

    params = NewUrlParams(rsp)
    oa.authtoken = params.get("oauth_token")
    oa.authsecret = params.get("oauth_token_secret")
    oa.resetHmac()

    if (oa.linked()) then
        oa.save()
        print "RegScreen: final oauth: "; oa.dump()
        status = 0
    else
        print "RegScreen: failed to retrieve final authorization token"
    end if

    return status
End Function


'******************************************************
'Load/Save a set of parameters to registry
'These functions must be called from an AA that has
'a "section" string and an "items" list of strings.
'******************************************************
Function loadReg() As Boolean
    for each item in m.items
        temp =  RegRead(item, m.section)
        if (temp = invalid) then
            temp = ""
        end if
        m[item] = temp
    end for
    return definedReg()
End Function

Function saveReg()
    for each item in m.items
        RegWrite(item, m[item], m.section)
    end for
End Function

Function eraseReg()
    for each item in m.items
        RegDelete(item, m.section)
        m[item] = ""
    end for
End Function

Function definedReg() As Boolean
    for each item in m.items
        if (not(m.DoesExist(item))) then
            return false
        end if
        if (Len(m[item]) = 0) then
            return false
        end if
    end for
    return true
End Function

Function dumpReg() As String
    result = ""
    for each item in m.items
        if (m.DoesExist(item)) then
            result = result + " " + item + "=" + m[item]
        end if
    end for
    return result
End Function

'********************************************************************
'** Fetch the prelink code from the registration service. return
'** valid registration code on success or an empty string on failure
'********************************************************************
Function getRegistrationCode(sn As String) As String
    if (sn = "") then
        return ""
    end if

    oa = Oauth()
    youtube = LoadYouTube()

    http = NewHttp(youtube.link_prefix+"/getRegCode?partner=roku&service=youtube&deviceTypeName=roku&deviceID="+sn+"&oauth_token="+oa.authtoken)
    print "RegScreen: access_token URL: "; http.GetUrl()

    rsp = http.getToStringWithTimeout(10)

    xml=ParseXML(rsp)
    print "GOT: " + rsp
    print "Reason: " + http.Http.GetFailureReason()

    if (xml = invalid) then
        print "Can't parse getRegistrationCode response"
        ShowConnectionFailed()
        return ""
    end if

    if (xml.GetName() <> "result") then
        Dbg("Bad register response: ",  xml.GetName())
        ShowConnectionFailed()
        return ""
    end if

    if (islist(xml.GetBody()) = false) then
        Dbg("No registration information available")
        ShowConnectionFailed()
        return ""
    end if

    'default values for retry logic
    retryInterval = 30  'seconds
    retryDuration = 900 'seconds (aka 15 minutes)
    regCode = ""

    'handle validation of response fields
    for each e in xml.GetBody()
        if (e.GetName() = "regCode") then
            regCode = e.GetBody()  'enter this code at website
        else if (e.GetName() = "retryInterval") then
            retryInterval = strtoi(e.GetBody())
        else if (e.GetName() = "retryDuration") then
            retryDuration = strtoi(e.GetBody())
        end if
    next

    if (regCode = "") then
        Dbg("Parse yields empty registration code")
        ShowConnectionFailed()
    end if

    m.retryDuration = retryDuration
    m.retryInterval = retryInterval
    m.regCode = regCode

    return regCode
End Function

Function displayRegistrationScreen() As Object
    youtube = LoadYouTube()

    regsite   = youtube.link_prefix
    regscreen = CreateObject("roCodeRegistrationScreen")
    regscreen.SetMessagePort(CreateObject("roMessagePort"))

    regscreen.SetTitle("")
    regscreen.AddParagraph("Please link your Roku player to your YouTube account")
    regscreen.AddFocalText(" ", "spacing-dense")
    regscreen.AddFocalText("From your computer, go to", "spacing-dense")
    regscreen.AddFocalText(regsite, "spacing–dense")
    regscreen.AddFocalText("and enter this code to activate:", "spacing-dense")
    regscreen.SetRegistrationCode("retrieving code...")
    regscreen.AddParagraph("This screen will automatically update as soon as your activation completes")
    regscreen.AddButton(0, "Get a new code")
    regscreen.AddButton(1, "Back")
    regscreen.Show()

    return regscreen
End Function

'******************************************************************
'** Check the status of the registration to see if we've linked
'** Returns:
'**     0 - We're registered. Proceed.
'**     1 - Reserved. Used by calling function.
'**     2 - We're not registered. There was an error, abort.
'**     3 - We're not registered. Keep trying.
'******************************************************************
Function checkRegistrationStatus(sn As String, regCode As String) As Integer
    oa = Oauth()
    youtube = LoadYouTube()

    print "checking registration status"
    http = NewHttp(youtube.link_prefix+"/getRegResult?service=youtube&partner=roku&deviceID="+sn+"&regCode="+regCode)

    while (true)
        rsp = http.getToStringWithTimeout(10)
        print rsp
        xml=ParseXML(rsp)
        if (xml = invalid) then
            print "Can't parse check registration status response"
            ShowConnectionFailed()
            return 2
        end if

        if (xml.GetName() <> "result") then
            print "unexpected check registration status response: ", xml.GetName()
            ShowConnectionFailed()
            return 2
        end if

        if (islist(xml.GetBody()) = true) then
            for each e in xml.GetBody()
                if (e.GetName() = "status") then
                    status = e.GetBody()

                    if (status = "failure") then
                        ShowConnectionFailed()
                        return 2
                    else if (status = "incomplete") then
                        return 3
                    end if
                else if (e.GetName() = "oauth_verifier") then
                    print "got oauth_verifier: "+e.GetBody()
                    oa.verifier = e.GetBody()
                    return 0
                end if
            next
        end if
    end while
End Function

'******************************************************
'Show congratulations screen
'******************************************************
Sub showCongratulationsScreen()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("Congratulations!")
    screen.AddParagraph("You have successfully linked your Roku player to your YouTube account.")
    screen.AddParagraph("Select 'start' to begin.")
    screen.AddButton(1, "start")
    screen.Show()

    while (true)
        msg = wait(0, screen.GetMessagePort())

        if (type(msg) = "roParagraphScreenEvent") then
            if (msg.isScreenClosed()) then
                print "Screen closed"
                exit while
            else if (msg.isButtonPressed()) then
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub