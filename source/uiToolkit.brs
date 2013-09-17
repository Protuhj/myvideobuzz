
'  uitkDoPosterMenu
'
'    Display "menu" items in a Poster Screen.
'
Function uitkPreShowPosterMenu(ListStyle="flat-category" as String, breadA = "Home", breadB = invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    if (breadA <> invalid and breadB <> invalid) then
        screen.SetBreadcrumbText(breadA, breadB)
    else if (breadA <> invalid and breadB = invalid) then
        screen.SetBreadcrumbText(breadA, "")
        screen.SetTitle(breadA)
    end if

    if (ListStyle = "" OR ListStyle = invalid) then
        ListStyle = "flat-category"
    end if

    screen.SetListStyle(ListStyle)
    screen.SetListDisplayMode("scale-to-fit")
    ' screen.SetListDisplayMode("zoom-to-fill")
    screen.Show()

    return screen
end function


Function uitkDoPosterMenu(posterdata, screen, onselect_callback=invalid) As Integer

    if (type(screen) <> "roPosterScreen") then
        'print "illegal type/value for screen passed to uitkDoPosterMenu()"
        return -1
    end if

    screen.SetContentList(posterdata)

    while (true)
        msg = wait(0, screen.GetMessagePort())

        'print "uitkDoPosterMenu | msg type = ";type(msg)

        if (type(msg) = "roPosterScreenEvent") then
            'print "event.GetType()=";msg.GetType(); " event.GetMessage()= "; msg.GetMessage()
            if (msg.isListItemSelected()) then
                if (onselect_callback <> invalid) then
                    selecttype = onselect_callback[0]
                    if (selecttype = 0) then
                        this = onselect_callback[1]
                        selected_callback = onselect_callback[msg.GetIndex() + 2]
                        if (islist(selected_callback)) then
                            f = selected_callback[0]
                            userdata1 = selected_callback[1]
                            userdata2 = selected_callback[2]
                            userdata3 = selected_callback[3]

                            if (userdata1 = invalid) then
                                this[f]()
                            else if (userdata2 = invalid) then
                                this[f](userdata1)
                            else if (userdata3 = invalid) then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if (selected_callback = "return") then
                                return msg.GetIndex()
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if (selecttype = 1) then
                        userdata1 = onselect_callback[1]
                        userdata2 = onselect_callback[2]
                        f = onselect_callback[3]
                        f(userdata1, userdata2, msg.GetIndex())
                    end if
                else
                    return msg.GetIndex()
                end if
            else if (msg.isScreenClosed()) then
                return -1
            end if
        end if
    end while
End Function


Function uitkPreShowListMenu(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roListScreen")
    screen.SetMessagePort(port)
    if (breadA <> invalid and breadB <> invalid) then
        screen.SetBreadcrumbText(breadA, breadB)
    end if
    'screen.SetListStyle("flat-category")
    'screen.SetListDisplayMode("best-fit")
    'screen.SetListDisplayMode("zoom-to-fill")
    screen.Show()

    return screen
end function


Function uitkDoListMenu(posterdata, screen, onselect_callback=invalid) As Integer

    if (type(screen) <> "roListScreen") then
        'print "illegal type/value for screen passed to uitkDoListMenu()"
        return -1
    end if

    screen.SetContent(posterdata)

    while (true)
        msg = wait(0, screen.GetMessagePort())

        'print "uitkDoPosterMenu | msg type = ";type(msg)

        if (type(msg) = "roListScreenEvent") then
            'print "event.GetType()=";msg.GetType(); " Event.GetMessage()= "; msg.GetMessage()
            if (msg.isListItemSelected()) then
                if (onselect_callback <> invalid) then
                    selecttype = onselect_callback[0]
                    if (selecttype = 0) then
                        this = onselect_callback[1]
                        selected_callback = onselect_callback[msg.GetIndex() + 2]
                        if (islist(selected_callback)) then
                            f = selected_callback[0]
                            userdata1 = selected_callback[1]
                            userdata2 = selected_callback[2]
                            userdata3 = selected_callback[3]

                            if (userdata1 = invalid) then
                                this[f]()
                            else if (userdata2 = invalid) then
                                this[f](userdata1)
                            else if (userdata3 = invalid) then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if (selected_callback = "return") then
                                return msg.GetIndex()
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if (selecttype = 1) then
                        userdata1=onselect_callback[1]
                        userdata2=onselect_callback[2]
                        f=onselect_callback[3]
                        f(userdata1, userdata2, msg.GetIndex())
                    end if
                else
                    return msg.GetIndex()
                end if
            else if (msg.isScreenClosed()) then
                return -1
            end if
        end if
    end while
End Function


Function uitkDoCategoryMenu(categoryList, screen, content_callback, onclick_callback) As Integer
    'Set current category to first in list
    category_idx = 0
    contentlist = []

    screen.SetListNames(categoryList)
    contentdata1 = content_callback[0]
    contentdata2 = content_callback[1]
    content_f = content_callback[2]

    contentlist=content_f(contentdata1, contentdata2, 0)

    if (contentlist.Count() = 0) then
        screen.SetContentList([])
        screen.clearmessage()
        screen.showmessage("No viewable content in this section")
    else
        screen.SetContentList(contentlist)
        screen.clearmessage()
    end if
    screen.Show()

    while (true)
        msg = wait(0, screen.GetMessagePort())
        if (type(msg) = "roPosterScreenEvent") then
            if (msg.isListFocused()) then
                category_idx = msg.GetIndex()
                contentdata1 = content_callback[0]
                contentdata2 = content_callback[1]
                content_f = content_callback[2]

                contentlist = content_f(contentdata1, contentdata2, category_idx)

                if (contentlist.Count() = 0) then
                    screen.SetContentList([])
                    screen.ShowMessage("No viewable content in this section")
                else
                    screen.SetContentList(contentlist)
                    screen.SetFocusedListItem(0)
                end if
            else if (msg.isListItemSelected()) then
                userdata1 = onclick_callback[0]
                userdata2 = onclick_callback[1]
                content_f = onclick_callback[2]

                contentlist = content_f(userdata1, userdata2, contentlist, category_idx, msg.GetIndex())
                if (contentlist.Count() <> 0) then
                    screen.SetContentList(contentlist)
                    screen.SetFocusedListItem(msg.GetIndex())
                end if
            else if (msg.isScreenClosed()) then
                return -1
            end if
        end If
    end while
End Function

Sub uitkDoMessage(message, screen)
    screen.showMessage(message)
    while (true)
        msg = wait(0, screen.GetMessagePort())
        if (msg.isScreenClosed()) then
            return
        end if
    end while
End Sub