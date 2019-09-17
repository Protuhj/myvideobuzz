
'******************************************************
' Show basic message dialog without buttons
' Dialog remains up until caller releases the returned object
'******************************************************
Function ShowPleaseWait(title As String, text = "" As String) As Object
    if (not(isstr(title))) then
        title = ""
    end if
    if (not(isstr(text))) then
        text = ""
    end if

    port = CreateObject("roMessagePort")
    dialog = invalid

    'the OneLineDialog renders a single line of text better
    'than the MessageDialog.
    if (text = "") then
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    end if

    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function

'******************************************************
'Retrieve text for connection failed
'******************************************************
Function GetConnectionFailedText() as String
    return "We were unable to connect to the service.  Please try again in a few minutes."
End Function

'******************************************************
' Show connection error dialog with only an OK button
'******************************************************
Sub ShowConnectionFailed( source = "" as String )
    getYoutube().CloseWaitDialog()
    Dbg("Connection Failed: " + source)
    title = "Can't connect to service"
    text  = GetConnectionFailedText()
    ShowErrorDialog(text, title)
End Sub

'******************************************************
' Show error dialog with OK button
'******************************************************
Sub ShowErrorDialog(text As dynamic, title = invalid as dynamic)
    getYoutube().CloseWaitDialog()
    if (not(isstr(text))) then
        text = "Unspecified error"
    end if
    if (not(isstr(title))) then
        title = "Error"
    end if
    ShowDialog1Button(title, text, "Done")
End Sub

'******************************************************
' Show 1 button dialog
' Return: nothing
'******************************************************
Sub ShowDialog1Button(title As Dynamic, text As Dynamic, but1 As String, quickReturn = false As Boolean)
    getYoutube().CloseWaitDialog()
    if (not(isstr(title))) then
        title = ""
    end if
    if (not(isstr(text))) then
        text = ""
    end if

    port = CreateObject( "roMessagePort" )
    dialog = CreateObject( "roMessageDialog" )
    dialog.SetMessagePort( port )

    dialog.SetTitle( title )
    dialog.SetText( text )
    dialog.AddButton( 0, but1 )
    dialog.Show()

    if ( quickReturn = true ) then
        return
    end if

    while ( true )
        dlgMsg = wait( 2000, dialog.GetMessagePort() )

        if ( type( dlgMsg ) = "roMessageDialogEvent" ) then
            if ( dlgMsg.isScreenClosed() ) then
                return
            else if ( dlgMsg.isButtonPressed() ) then
                return
            end if
        else if ( dlgMsg = invalid ) then
            CheckForMCast()
        end if
    end while
End Sub

'******************************************************
'Show 2 button dialog
'Return: 0=first button or screen closed, 1=second button
'******************************************************
Function ShowDialog2Buttons(title As dynamic, text As dynamic, but1 As String, but2 As String) As Integer
    getYoutube().CloseWaitDialog()
    if (not(isstr(title))) then
        title = ""
    end if
    if (not(isstr(text))) then
        text = ""
    end if

    Dbg("DIALOG2: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.SetMenuTopLeft( true )
    dialog.AddButton(1, but1)
    dialog.AddButton(2, but2)
    dialog.Show()

    while (true)
        dlgMsg = wait(2000, dialog.GetMessagePort())

        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isScreenClosed()) then
                'print "Screen closed"
                dialog = invalid
                return 0
            else if (dlgMsg.isButtonPressed()) then
                'print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                dialog = invalid
                return dlgMsg.GetIndex()
            end if
        else if (dlgMsg = invalid) then
            CheckForMCast()
        end if
    end while
End Function

'******************************************************
'Get input from the keyboard
'******************************************************
Function getKeyboardInput(title As String, search_text As String, default_text = "" as String, submit_text="Submit" As String, cancel_text="Cancel" As String)
    getYoutube().CloseWaitDialog()
    screen = CreateObject( "roKeyboardScreen" )
    port = CreateObject( "roMessagePort" )

    screen.SetMessagePort( port )
    screen.SetTitle( title )
    screen.SetText( default_text )
    screen.SetDisplayText( search_text )
    screen.AddButton( 1, submit_text )
    screen.AddButton( 2, cancel_text )
    screen.Show()

    while ( true )
        msg = wait( 2000, screen.GetMessagePort() )

        if ( type( msg ) = "roKeyboardScreenEvent" ) then
            if ( msg.isScreenClosed() ) then
                return invalid
            else if ( msg.isButtonPressed() ) then
                if ( msg.GetIndex() = 1 ) then
                    inputText = screen.GetText().Trim()
                    return inputText
                else
                    return invalid
                end if
            end if
        else if ( msg = invalid ) then
            CheckForMCast()
        end if
    end while
End Function

'******************************************************
'Show basic message dialog without buttons
'Dialog remains up until caller releases the returned object
'******************************************************
Function ShowDialogNoButton(title As dynamic, text As dynamic) As Object
    getYoutube().CloseWaitDialog()
    if (not(isstr(title))) then
        title = ""
    end if
    if (not(isstr(text))) then
        text = ""
    end if

    port = CreateObject("roMessagePort")
    dialog = invalid

    'the OneLineDialog renders a single line of text better
    'than the MessageDialog.
    if (text = "") then
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    end if

    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.Show()
    return dialog
End Function