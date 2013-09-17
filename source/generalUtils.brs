
'******************************************************
'Registry Helper Functions
'******************************************************
Function RegRead(key, section=invalid)
    if (section = invalid) then
        section = "Default"
    end if
    sec = CreateObject("roRegistrySection", section)
    if (sec.Exists(key)) then
        return sec.Read(key)
    end if
    return invalid
End Function

Function RegWrite(key, val, section=invalid)
    if (section = invalid) then
        section = "Default"
    end if
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
End Function

Function RegDelete(key, section=invalid)
    if (section = invalid) then
        section = "Default"
    end if
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
End Function

' registry tools
Function RegistryDump() as integer
    print "Dumping Registry"
    r = CreateObject("roRegistry")
    sections = r.GetSectionList()
    if (sections.Count() = 0) then
        print "No sections in registry"
    end if
    for each section in sections
        print "section=";section
        s = CreateObject("roRegistrySection",section)
        keys = s.GetKeyList()
        for each key in keys
            val = s.Read(key)
            print "    ";key;" : "; val
        end for
    end for
    return sections.Count()
End Function

'*************************************************************'
'*                     SORT ROUTINES                         *'
'*************************************************************'

' simple quicksort of an array of values
Function internalQSort(A as Object, left as integer, right as integer) as void
    i = left
    j = right
    pivot = A[(left+right)/2]
    while (i <= j)
        while (A[i] < pivot)
            i = i + 1
        end while
        while (A[j] > pivot)
            j = j - 1
        end while
        if (i <= j) then
            tmp = A[i]
            A[i] = A[j]
            A[j] = tmp
            i = i + 1
            j = j - 1
        end if
    end while
    if (left < j) then
        internalQSort(A, left, j)
    end if
    if (i < right) then
        internalQSort(A, i, right)
    end if
End Function

' quicksort an array using a function to extract the compare value
Function internalKeyQSort(A as Object, key as object, left as integer, right as integer) as void
    i = left
    j = right
    pivot = key(A[(left+right)/2])
    while (i <= j)
        while (key(A[i]) < pivot)
            i = i + 1
        end while
        while (key(A[j]) > pivot)
            j = j - 1
        end while
        if (i <= j) then
            tmp = A[i]
            A[i] = A[j]
            A[j] = tmp
            i = i + 1
            j = j - 1
        end if
    end while
    if (left < j) then
        internalKeyQSort(A, key, left, j)
    end if
    if (i < right) then
        internalKeyQSort(A, key, i, right)
    end if
End Function

' quicksort an array using an indentically sized array that holds the comparison values
Function internalKeyArrayQSort(A as Object, keys as object, left as integer, right as integer) as void
    i = left
    j = right
    pivot = keys[A[(left+right)/2]]
    while (i <= j)
        while (keys[A[i]] < pivot)
            i = i + 1
        end while
        while (keys[A[j]] > pivot)
            j = j - 1
        end while
        if (i <= j) then
            tmp = A[i]
            A[i] = A[j]
            A[j] = tmp
            i = i + 1
            j = j - 1
        end if
    end while
    if (left < j) then
        internalKeyArrayQSort(A, keys, left, j)
    end if
    if (i < right) then
        internalKeyArrayQSort(A, keys, i, right)
    end if
End function

'******************************************************
' QuickSort(Array, optional keys function or array)
' Will sort an array directly
' If key is a function it is called to get the value for comparison
' If key is an identically sized array as the array to be sorted then
' the comparison values are pulled from there. In this case the Array
' to be sorted should be an array if integers 0 .. arraysize-1
'******************************************************
Sub QuickSort(A as Object, key=invalid as dynamic)
    atype = type(A)
    if (atype <> "roArray") then
        return
    end if
    ' weed out trivial arrays
    arraysize = A.Count()
    if (arraysize < 2) then
        return
    end if
    if (key = invalid) then
        internalQSort(A, 0, arraysize - 1)
    else
        keytype = type(key)
        if (keytype = "Function") then
            internalKeyQSort(A, key, 0, arraysize - 1)
        else if ((keytype="roArray" or keytype="Array") and (key.count() = arraysize)) then
            internalKeyArrayQSort(A, key, 0, arraysize - 1)
        end if
    end if
End Sub

'******************************************************
'Insertion Sort
'Will sort an array directly, or use a key function
'******************************************************
Sub Sort(A as Object, key=invalid as dynamic)

    if (type(A) <> "roArray") then
        return
    end if

    if (key = invalid) then
        for i = 1 to A.Count()-1
            value = A[i]
            j = i-1
            while (j >= 0 and A[j] > value)
                A[j + 1] = A[j]
                j = j-1
            end while
            A[j+1] = value
        next
    else
        if (type(key) <> "Function") then
            return
        end if
        for i = 1 to A.Count()-1
            valuekey = key(A[i])
            value = A[i]
            j = i-1
            while (j >= 0 and key(A[j]) > valuekey)
                A[j + 1] = A[j]
                j = j-1
            end while
            A[j+1] = value
        next

    end if

End Sub

' insert value into array
Sub SortedInsert(A as object, value as string)
    count = a.count()
    a.push(value)       ' use push to make sure array size is correct now
    if (count = 0) then
        return
    end if
    ' should do a binary search, but at least this is better than push and sort
    for i = count-1 to 0 step -1
        if (value >= a[i]) then
            a[i+1] = value
            return
        end if
        a[i+1] = a[i]
    end for
    a[0] = value
End Sub


'******************************************************'
'*         MISC UTILITIES                             *'
'******************************************************'

'******************************************************
'Convert anything to a string
'
'Always returns a string
'******************************************************
Function tostr(any) as String
    ret = AnyToString(any)
    if (ret = invalid) then
        ret = type(any)
    end if
    if (ret = invalid) then
        ret = "unknown" 'failsafe
    end if
    return ret
End Function

'******************************************************
'Get a " char as a string
'******************************************************
Function Quote() as String
    q$ = Chr(34)
    return q$
End Function

'******************************************************
'Determine if the given object supports the ifXMLElement interface
'******************************************************
Function isxmlelement(obj as dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (GetInterface(obj, "ifXMLElement") = invalid) then
        return false
    end if
    return true
End Function


'******************************************************
'Determine if the given object supports the ifList interface
'******************************************************
Function islist(obj as dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (GetInterface(obj, "ifArray") = invalid) then
        return false
    end if
    return true
End Function

'******************************************************
' Determine if the given object supports the ifInt interface
'******************************************************
Function isint(obj as dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (GetInterface(obj, "ifInt") = invalid) then
        return false
    end if
    return true
End Function

'******************************************************
' Determine if the given argument is a function
' @param obj the object to test
' @return true if obj is a Function, false if it is not
'******************************************************
Function isfunc(obj as dynamic) As Boolean
    tf = type(obj)
    return (tf = "Function" or tf = "roFunction")
End Function

'******************************************************
' always return a valid string. if the argument is
' invalid or not a string, return an empty string
'******************************************************
Function validstr(obj As Dynamic) As String
    if (isnonemptystr(obj)) then
        return obj
    end if
    return ""
End Function

'******************************************************
' Determine if the given object supports the ifString interface
'******************************************************
Function isstr(obj as dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (GetInterface(obj, "ifString") = invalid) then
        return false
    end if
    return true
End Function

'******************************************************
' Determine if the given object supports the ifString interface
' and returns a string of non zero length
'******************************************************
Function isnonemptystr(obj)
    if (isnullorempty(obj)) then
        return false
    end if
    return true
End Function

'******************************************************
' Determine if the given object is invalid or supports
' the ifString interface and returns a string of non zero length
'******************************************************
Function isnullorempty(obj) as Boolean
    if (obj = invalid) then
        return true
    end if
    if (not isstr(obj)) then
        return true
    end if
    if (Len(obj) = 0) then
        return true
    end if
    return false
End Function

'******************************************************
' Determine if the given object supports the ifBoolean interface
'******************************************************
Function isbool(obj as dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (GetInterface(obj, "ifBoolean") = invalid) then
        return false
    end if
    return true
End Function


'******************************************************
' Determine if the given object supports the ifFloat interface
'******************************************************
Function isfloat(obj as dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (GetInterface(obj, "ifFloat") = invalid) then
        return false
    end if
    return true
End Function


'******************************************************
' Convert string to boolean safely. Don't crash
' Looks for certain string values
'******************************************************
Function strtobool(obj As dynamic) As Boolean
    if (obj = invalid) then
        return false
    end if
    if (type(obj) <> "roString") then
        return false
    end if
    o = strTrim(obj)
    o = Lcase(o)
    if (o = "true") then
        return true
    end if
    if (o = "t") then
        return true
    end if
    if (o = "y") then
        return true
    end if
    if (o = "1") then
        return true
    end if
    return false
End Function

'******************************************************
' Convert int to string. This is necessary because
' the builtin Stri(x) prepends whitespace
'******************************************************
Function itostr(i As Integer) As String
    str = Stri(i)
    return strTrim(str)
End Function

'******************************************************
' Get 'aining hours from a total seconds
'******************************************************
Function hoursLeft(seconds As Integer) As Integer
    hours% = seconds / 3600
    return hours%
End Function

'******************************************************
' Get 'aining minutes from a total seconds
'******************************************************
Function minutesLeft(seconds As Integer) As Integer
    hours% = seconds / 3600
    mins% = seconds - (hours% * 3600)
    mins% = mins% / 60
    return mins%
End Function

'******************************************************
' Pluralize simple strings like "1 minute" or "2 minutes"
'******************************************************
Function Pluralize(val As Integer, str As String) As String
    ret = itostr(val) + " " + str
    if (val <> 1) then
        ret = ret + "s"
    end if
    return ret
End Function

'******************************************************
' Trim a string
'******************************************************
Function strTrim(str As String) As String
    st=CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function


'******************************************************
' Tokenize a string. Return roList of strings
'******************************************************
Function strTokenize(str As String, delim As String) As Object
    st = CreateObject("roString")
    st.SetString(str)
    return st.Tokenize(delim)
End Function

'******************************************************
' Replace substrings in a string. Return new string
'******************************************************
Function strReplace(basestr As String, oldsub As String, newsub As String) As String
    newstr = ""

    i = 1
    while (i <= Len(basestr))
        x = Instr(i, basestr, oldsub)
        if (x = 0) then
            newstr = newstr + Mid(basestr, i)
            exit while
        end if

        if (x > i) then
            newstr = newstr + Mid(basestr, i, x-i)
            i = x
        end if

        newstr = newstr + newsub
        i = i + Len(oldsub)
    end while

    return newstr
End Function

'******************************************************
' Get all XML subelements by name
'
' return list of 0 or more elements
'******************************************************
Function GetXMLElementsByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if (not(islist(xml.GetBody()))) then
        return list
    end if

    for each e in xml.GetBody()
        if (e.GetName() = name) then
            list.Push(e)
        end if
    next

    return list
End Function

'******************************************************
' Get all XML subelement's string bodies by name
'
' return list of 0 or more strings
'******************************************************
Function GetXMLElementBodiesByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if (not(islist(xml.GetBody()))) then
        return list
    end if

    for each e in xml.GetBody()
        if (e.GetName() = name) then
            b = e.GetBody()
            if (type(b) = "roString") then
                list.Push(b)
            end if
        end if
    next

    return list
End Function

'******************************************************
' Get first XML subelement by name
'
' return invalid if not found, else the element
'******************************************************
Function GetFirstXMLElementByName(xml As Object, name As String) As Dynamic
    if (not(islist(xml.GetBody()))) then
        return invalid
    end if

    for each e in xml.GetBody()
        if (e.GetName() = name) then
            return e
        end if
    next

    return invalid
End Function

'******************************************************
' Get first XML subelement's string body by name
'
' return invalid if not found, else the subelement's body string
'******************************************************
Function GetFirstXMLElementBodyStringByName(xml As Object, name As String) As Dynamic
    e = GetFirstXMLElementByName(xml, name)
    if (e = invalid) then
        return invalid
    end if
    if (type(e.GetBody()) <> "roString") then
        return invalid
    end if
    return e.GetBody()
End Function

'******************************************************
' Get the xml element as an integer
'
' return invalid if body not a string, else the integer as converted by strtoi
'******************************************************
Function GetXMLBodyAsInteger(xml As Object) As Dynamic
    if (type(xml.GetBody()) <> "roString") then
        return invalid
    end if
    return strtoi(xml.GetBody())
End Function


'******************************************************
' Parse a string into a roXMLElement
'
' return invalid on error, else the xml object
'******************************************************
Function ParseXML(str As String) As Dynamic
    if (str = invalid) then
        return invalid
    end if
    xml = CreateObject("roXMLElement")
    if (not(xml.Parse(str))) then
        return invalid
    end if
    return xml
End Function

'******************************************************
' Get XML sub elements whose bodies are strings into an associative array.
' subelements that are themselves parents are skipped
' namespace :'s are replaced with _'s
'
' So an XML element like...
'
' <blah>
'     <This>abcdefg</This>
'     <Sucks>xyz</Sucks>
'     <sub>
'         <sub2>
'         ....
'         </sub2>
'     </sub>
'     <ns:doh>homer</ns:doh>
' </blah>
'
' returns an AA with:
'
' aa.This = "abcdefg"
' aa.Sucks = "xyz"
' aa.ns_doh = "homer"
'
' return an empty AA if nothing found
'******************************************************
Sub GetXMLintoAA(xml As Object, aa As Object)
    for each e in xml.GetBody()
        body = e.GetBody()
        if (type(body) = "roString") then
            name = e.GetName()
            name = strReplace(name, ":", "_")
            aa.AddReplace(name, body)
        end if
    next
End Sub

'******************************************************
' Walk an AA and print it
'******************************************************
Sub PrintAA(aa as Object)
    print "---- AA ----"
    if (aa = invalid) then
        print "invalid"
        return
    else
        cnt = 0
        for each e in aa
            x = aa[e]
            PrintAny(0, e + ": ", aa[e])
            cnt = cnt + 1
        next
        if (cnt = 0) then
            PrintAny(0, "Nothing from foreach. Looks like :", aa)
        end if
    end if
    print "------------"
End Sub

'******************************************************
' Walk a list and print it
'******************************************************
Sub PrintList(list as Object)
    print "---- list ----"
    PrintAnyList(0, list)
    print "--------------"
End Sub

'******************************************************
' Print an associativearray
'******************************************************
Sub PrintAnyAA(depth As Integer, aa as Object)
    for each e in aa
        x = aa[e]
        PrintAny(depth, e + ": ", aa[e])
    next
End Sub

'******************************************************
' Print a list with indent depth
'******************************************************
Sub PrintAnyList(depth As Integer, list as Object)
    i = 0
    for each e in list
        PrintAny(depth, "List(" + itostr(i) + ")= ", e)
        i = i + 1
    next
End Sub

'******************************************************
' Print anything
'******************************************************
Sub PrintAny(depth As Integer, prefix As String, any As Dynamic)
    if (depth >= 10) then
        print "**** TOO DEEP, limiting to 10.. " + itostr(5)
        depth = 10
    end if
    prefix = string(depth * 2," ") + prefix
    depth = depth + 1
    str = AnyToString(any)
    if (str <> invalid) then
        print prefix + str
        return
    end if
    if (type(any) = "roAssociativeArray") then
        print prefix + "(assocarr)..."
        PrintAnyAA(depth, any)
        return
    end if
    if (islist(any) = true) then
        print prefix + "(list of " + itostr(any.Count()) + ")..."
        PrintAnyList(depth, any)
        return
    end if

    print prefix + "?" + type(any) + "?"
End Sub

'******************************************************
' Print an object as a string for debugging. If it is
' very long print the first 500 chars.
'******************************************************
Sub Dbg(pre As Dynamic, o=invalid As Dynamic)
    p = AnyToString(pre)
    if (p = invalid) then
        p = ""
    end if
    if (o = invalid) then
        o = ""
    end if
    s = AnyToString(o)
    if (s = invalid) then
        s = "???: " + type(o)
    end if
    if (Len(s) > 4000) then
        s = Left(s, 4000)
    end if
    print p + s
End Sub

'******************************************************
' Try to convert anything to a string. Only works on simple items.
'
' Test with this script...
'
'     s$ = "yo1"
'     ss = "yo2"
'     i% = 111
'     ii = 222
'     f! = 333.333
'     ff = 444.444
'     d# = 555.555
'     dd = 555.555
'     bb = true
'
'     so = CreateObject("roString")
'     so.SetString("strobj")
'     io = CreateObject("roInt")
'     io.SetInt(666)
'     tm = CreateObject("roTimespan")
'
'     Dbg("", s$ ) 'call the Dbg() function which calls AnyToString()
'     Dbg("", ss )
'     Dbg("", "yo3")
'     Dbg("", i% )
'     Dbg("", ii )
'     Dbg("", 2222 )
'     Dbg("", f! )
'     Dbg("", ff )
'     Dbg("", 3333.3333 )
'     Dbg("", d# )
'     Dbg("", dd )
'     Dbg("", so )
'     Dbg("", io )
'     Dbg("", bb )
'     Dbg("", true )
'     Dbg("", tm )
'
' try to convert an object to a string. return invalid if can't
'******************************************************
Function AnyToString(any As Dynamic) As Dynamic
    if (any = invalid) then
        return "invalid"
    end if
    if (isstr(any)) then
        return any
    end if
    if (isint(any)) then
        return itostr(any)
    end if
    if (isbool(any)) then
        if (any = true) then
            return "true"
        end if
        return "false"
    end if
    if (isfloat(any)) then
        return Str(any)
    end if
    if (type(any) = "roTimespan") then
        return itostr(any.TotalMilliseconds()) + "ms"
    end if
    return invalid
End Function

'******************************************************
' Walk an XML tree and print it
'******************************************************
Sub PrintXML(element As Object, depth As Integer)
    print tab(depth*3);"Name: [" + element.GetName() + "]"
    if (invalid <> element.GetAttributes()) then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 4000);
            if (element.GetAttributes().IsNext()) then
                print ", ";
            end if
        next
        print
    end if

    if (element.GetBody() = invalid) then
        ' print tab(depth*3);"No Body"
    else if (type(element.GetBody()) = "roString") then
        print tab(depth*3);"Contains string: [" + left(element.GetBody(), 4000) + "]"
    else
        print tab(depth*3);"Contains list:"
        for each e in element.GetBody()
            PrintXML(e, depth+1)
        next
    end if
    print
end sub

'******************************************************
' Dump the bytes of a string
'******************************************************
Sub DumpString(str As String)
    print "DUMP STRING"
    print "---------------------------"
    print str
    print "---------------------------"
    l = Len(str)-1
    i = 0
    for i = 0 to l
        c = Mid(str, i)
        val = Asc(c)
        print itostr(val)
    next
    print "---------------------------"
End Sub

'******************************************************
' Validate parameter is the correct type
'******************************************************
Function validateParam(param As Object, paramType As String,functionName As String, allowInvalid = false) As Boolean
    if (type(param) = paramType) then
        return true
    end if

    if (allowInvalid = true) then
        if (type(param) = invalid) then
            return true
        end if
    end if

    print "invalid parameter of type "; type(param); " for "; paramType; " in function "; functionName
    return false
End Function

Function wrap(num As Integer, size As Dynamic) As Integer
    ' wraps via mod if size works
    ' else just clips negatives to zero
    ' (sort of an indefinite size wrap where we assume
    '  size is at least num and punt with negatives)
    remainder = num
    if (isint(size) and size <> 0) then
        base = int(num/size)*size
        remainder = num - base
    else if (num < 0) then
        remainder = 0
    end if
    return remainder
End Function

Function simpleJSONParser( jsonString As String ) As Object
        q = chr(34)

        beforeKey  = "[,{]"
        keyFiller  = "[^:]*?"
        keyNospace = "[-_\w\d]+"
        valueStart = "[" +q+ "\d\[{]|true|false|null"
        reReplaceKeySpaces = "("+beforeKey+")\s*"+q+"("+keyFiller+")("+keyNospace+")\s+("+keyNospace+")\s*"+q+"\s*:\s*(" + valueStart + ")"

        regexKeyUnquote = CreateObject( "roRegex", q + "([a-zA-Z0-9_\-\s]*)" + q + "\:", "i" )
        regexKeyUnspace = CreateObject( "roRegex", reReplaceKeySpaces, "i" )
        regexQuote = CreateObject( "roRegex", "\\" + q, "i" )

        ' setup "null" variable
        null = invalid

        ' Replace escaped quotes
        jsonString = regexQuote.ReplaceAll( jsonString, q + " + q + " + q )

        while (regexKeyUnspace.isMatch( jsonString ))
                jsonString = regexKeyUnspace.ReplaceAll( jsonString, "\1"+q+"\2\3\4"+q+": \5" )
        end while

        jsonString = regexKeyUnquote.ReplaceAll( jsonString, "\1:" )

        jsonObject = invalid
        ' Eval the BrightScript formatted JSON string
        Eval( "jsonObject = " + jsonString )
        Return jsonObject
End Function