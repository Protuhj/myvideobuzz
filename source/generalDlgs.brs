
'******************************************************
' Show basic message dialog without buttons
' Dialog 'ains up until caller releases the returned object
'******************************************************
Function ShowPleaseWait(title As String, text As Dynamic) As Object
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
'Show connection error dialog
'
'Parameter: retry t/f - offer retry option
'Return 0 = retry, 1 = back
'******************************************************
Function ShowConnectionFailedRetry() as dynamic
    Dbg("Connection Failed Retry")
    title = "Can't connect to service"
    text  = GetConnectionFailedText()
    return ShowDialog2Buttons(title, text, "Try Again", "Back")
End Function

'******************************************************
' Show connection error dialog with only an OK button
'******************************************************
Sub ShowConnectionFailed()
    Dbg("Connection Failed")
    title = "Can't connect to service"
    text  = GetConnectionFailedText()
    ShowErrorDialog(text, title)
End Sub

'******************************************************
' Show error dialog with OK button
'******************************************************
Sub ShowErrorDialog(text As dynamic, title = invalid as dynamic)
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
    if (not(isstr(title))) then
        title = ""
    end if
    if (not(isstr(text))) then
        text = ""
    end if

    Dbg("DIALOG1: ", title + " - " + text)

    port = CreateObject( "roMessagePort" )
    dialog = CreateObject( "roMessageDialog" )
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.Show()

    if (quickReturn = true) then
        return
    end if

    while (true)
        dlgMsg = wait(0, dialog.GetMessagePort())

        if (type(dlgMsg) = "roMessageDialogEvent") then
            if (dlgMsg.isScreenClosed()) then
                print "Screen closed"
                return
            else if (dlgMsg.isButtonPressed()) then
                'print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                return
            end if
        end if
    end while
End Sub

'******************************************************
'Show 2 button dialog
'Return: 0=first button or screen closed, 1=second button
'******************************************************
Function ShowDialog2Buttons(title As dynamic, text As dynamic, but1 As String, but2 As String) As Integer
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
    dialog.AddButton(0, but1)
    dialog.AddButton(1, but2)
    dialog.Show()

    while (true)
        dlgMsg = wait(0, dialog.GetMessagePort())

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
        end if
    end while
End Function

'******************************************************
'Get input from the keyboard
'******************************************************
Function getKeyboardInput(title As String, search_text As String, submit_text="Submit" As String, cancel_text="Cancel" As String)
    screen=CreateObject("roKeyboardScreen")
    port=CreateObject("roMessagePort")

    screen.SetMessagePort(port)
    screen.SetTitle(title)
    screen.SetDisplayText(search_text)
    screen.AddButton(1, submit_text)
    screen.AddButton(2, cancel_text)
    screen.Show()

    while (true)
        msg = wait(0, screen.GetMessagePort())

        if (type(msg) = "roKeyboardScreenEvent") then
            if (msg.isScreenClosed()) then
                return invalid
            else if (msg.isButtonPressed()) then
                if (msg.GetIndex() = 1) then
                    inputText = screen.GetText()
                    return inputText
                else
                    return invalid
                end if
            end if
        end if
    end while
End Function

'******************************************************
'Show basic message dialog without buttons
'Dialog 'ains up until caller releases the returned object
'******************************************************
Function ShowDialogNoButton(title As dynamic, text As dynamic) As Object
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
    'dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function