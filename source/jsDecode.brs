'
' This code was ported from python -- from the 'pafy' project
' Which can be found here: https://github.com/np1/pafy
'

Function decodesig(sig as String) as Dynamic
    '""" Return decrypted sig given an encrypted sig and js_url key. """
    ' lookup main function in funcmap
    mainfunction = getYoutube().funcmap
    if ( mainfunction <> invalid ) then
        ' PrintAA( mainfunction )
        mainfunction = mainfunction["mainfunction"]
        param = mainfunction["parameters"]
        if ( param.Count() <> 1 ) then
            print( "Main sig js function has more than one arg: " +  param )
            return invalid
        end if
        ' fill in function argument with signature
        mainfunction["args"] = {}
        mainfunction["args"][param[0]] = sig
        'print("testing: " + sig)
        solved = solve(mainfunction)
        'printAny( 5, "Solved: ", solved) 
        return solved
    else
        print( "no mainfunction in decodesig!" )
        return invalid
    end if
End Function

Function get_js_sm(video_id as String, waitDialog = invalid as Dynamic) as Dynamic
    ' Fetch watchinfo page and extract stream map and js funcs if not known.
    'This function is needed by videos with encrypted signatures.
    'If the js url referred to in the watchv page is not a key in Pafy.funcmap,
    'the javascript is fetched and functions extracted.
    'Returns streammap (list of dicts), js url (str) and funcs (dict)
    '
    jsplayer = CreateObject( "roRegex", Quote() + "assets" + Quote() + "\s*:\s*\{.*?" + Quote() + "js" + Quote() + "\s*:\s*" + Quote() + "(.*?)" + Quote(), "" )
    sts_val = CreateObject( "roRegex", Quote() + "sts" + Quote() + "\s*:\s*(\d+)", "" )
    slashRegex = CreateObject( "roRegex", "\\\/", "" )
    watch_url = "https://www.youtube.com/watch?v=" + video_id
    http = NewHttp( watch_url )
    headers = { }
    headers["User-Agent"] = getConstants().USER_AGENT
    'print("Fetching watch page")
    watchinfo = http.getToStringWithTimeout(10, headers)
    'print(watchinfo)
    ' Correct STS value is required for videos with encoded signatures
    stsMatch = sts_val.Match( watchinfo )
    stsValChanged = false
    if ( stsMatch.Count() > 1 ) then
        print "Found sts value: " + stsMatch[1]
        if ( getYoutube().STSVal <> stsMatch[1] ) then
            ' Don't write to the registry too often.
            ' Store the STS Value for use next time, in case it changes.
            RegWrite("YT_STS_VAL", stsMatch[1])
            print "STS value mismatch old: " + getYoutube().STSVal + " new: " + stsMatch[1] + " - forcing retry"
            getYoutube().STSVal = stsMatch[1]
            stsValChanged = true
        end if
    end if
    m = jsplayer.Match( watchinfo )
    if ( m.Count() > 1 ) then
        'print ("Found JS player: " + slashRegex.ReplaceAll(m[1], "/") )
        'stream_info = myjson["args"]
        'dash_url = stream_info['dashmpd']
        'sm = _extract_smap(g.UEFSM, stream_info, False)
        'asm = _extract_smap(g.AF, stream_info, False)
        js_url = slashRegex.ReplaceAll(m[1], "/")
        
        if ( js_url.InStr( 0, "youtube.com" ) = -1 ) then
            js_url = "https://www.youtube.com" + js_url
        else if ( Left( js_url, 2 ) = "//") then
            js_url = "https:" + js_url
        end if
        funcs = getYoutube().funcmap
        if ( funcs = invalid OR (getYoutube().JSUrl <> js_url) ) then
            if (waitDialog <> invalid) then
                if ( getPrefs().getPrefValue( getConstants().pROKU_ONE_SUPPORT ) = getConstants().DISABLED_VALUE )
                    waitDialog.UpdateText( "Downloading javascript file..." )
                else
                    waitDialog.SetText( "Downloading javascript file..." )
                end if
            end if
            jsHttp = NewHttp( js_url )
            headers = { }
            headers["User-Agent"] = getConstants().USER_AGENT
            javascript = jsHttp.getToStringWithTimeout(10, headers)
            if (waitDialog <> invalid) then
                if ( getPrefs().getPrefValue( getConstants().pROKU_ONE_SUPPORT ) = getConstants().DISABLED_VALUE )
                    waitDialog.UpdateText( "Parsing javascript..." )
                else
                    waitDialog.SetText( "Parsing javascript..." )
                end if
            end if
            mainfunc = getMainfuncFromJS(javascript)
            if ( mainfunc <> invalid ) then
                funcs = getOtherFuncs(mainfunc, javascript)
                funcs["mainfunction"] = mainfunc
                getYoutube().JSUrl = js_url
            else
                print( "Couldn't find mainfunc!" )
            end if
        else
            print("Using functions in memory extracted from " + js_url)
        end if
    end if
    if ( stsValChanged = true AND funcs <> invalid ) then
        funcs["stsValChanged"] = true
    end if
    return funcs
End Function

Function extractFunctionFromJS(funcName as String, jsBody as String) as Object
    ' Find a function definition called `name` and extract components.
    ' Return a dict representation of the function.

    ' Doesn't return entire function body -- regex is semi-garbage
    print("Extracting function '" + funcName + "' from javascript")
    fpattern = CreateObject( "roRegex", "(?:function\s+" + regexEscape( funcName ) + "|(?:var\s+)?" + regexEscape( funcName ) + "\s*=\s*function)\s*\(((?:\w+,?)+)\)\{([^}]+)\}(?:,\s*)?", "" )
    fMatch = fpattern.Match( jsBody )
    matchNum = 0
    ' Match[0] - whole matchNum
    ' Match[1] - argument list
    ' Match[2] - body
    retVal = {}
    retVal.name = funcname
    if ( fMatch.Count() > 2 )
        retVal.parameters = fMatch[1].Tokenize(",")
        retVal.body = fMatch[2]
        'printaa(retVal)
        'print( "extracted function " + retVal.name + " ###### body: " + retVal.body )
    else
        print ("Couldn't find function " + funcName)
        retVal = invalid
    end if
    return retVal
End Function

Function getMainfuncFromJS(jsBody as String) as Dynamic
    ' Return main signature decryption function from javascript as dict. """
    'print( "Scanning js for main function." )
    fpattern = CreateObject( "roRegex", "\bc\s*&&\s*d\.set\([^,]+\s*,\s*encodeURIComponent\(([a-zA-Z0-9$]+)\(", "" )
    patterns = []
    ' Push new patterns to the front of the list
    patterns.push({ pattern: CreateObject( "roRegex", "(?P<sig>[a-zA-Z0-9$]+)\s*=\s*function\(\s*a\s*\)\s*{\s*a\s*=\s*a\.split\(\s*" + Quote() + Quote() + "\s*\)", "" ), position: 1})
    patterns.push({ pattern: CreateObject( "roRegex", "\bc\s*&&\s*d\.set\([^,]+\s*,\s*\([^)]*\)\s*\(\s*(?P<sig>[a-zA-Z0-9$]+)\(", "" ), position: 1})
    patterns.push({ pattern: CreateObject( "roRegex", "\bc\s*&&\s*d\.set\([^,]+\s*,\s*(?P<sig>[a-zA-Z0-9$]+)\(", "" ), position: 1})
    patterns.push({ pattern: CreateObject( "roRegex", "yt\.akamaized\.net/\)\s*\|\|\s*.*?\s*c\s*&&\s*d\.set\([^,]+\s*,\s*(?P<sig>[a-zA-Z0-9$]+)\(", "" ), position: 1})
    patterns.push({ pattern: CreateObject( "roRegex", "([\" + Quote() + "\'])signature\1\s*,\s*([a-zA-Z0-9$]+)\(", "" ), position: 2})
    patterns.push({ pattern: CreateObject( "roRegex", "\w\.sig\|\|([$\w]+)\(\w+\.\w+\)", "" ), position: 2})
    patterns.push({ pattern: CreateObject( "roRegex", "\bc\s*&&\s*d\.set\([^,]+\s*,\s*encodeURIComponent\(([a-zA-Z0-9$]+)\(", "" ), position: 1 })
    count = 1
    for each pat in patterns
        matches = pat.pattern.Match( jsBody )
        if ( matches.Count() > 1 ) then
            funcname = matches[pat.position]
            print "[" ; count ; "] Found main function: " ; funcname
            funcBody = extractFunctionFromJS( funcname, jsBody )
            return funcBody
        end if
        count = count + 1
    next
    print "Failed to find main function!"
    return invalid
End Function

Function getOtherFuncs(primary_func as Object, jsText as String) as Object
    '""" Return all secondary functions used in primary_func. """
    'print("scanning javascript for secondary functions.")
    body = primary_func.body
    body = body.Tokenize(";")
    '# standard function call: X=F(A,B,C...)
    funcCall = CreateObject( "roRegex", "(?:[$\w+])=([$\w]+)\(((?:\w+,?)+)\)$", "" )
    '# dot notation function call: X=O.F(A,B,C..)
    dotCall = CreateObject( "roRegex", "(?:[$\w+]=)?([$\w]+)\.([$\w]+)\(((?:\w+,?)+)\)$", "" )
    '# dot notation function call: X=O["name"](A,B,C..)
    arrayCall = CreateObject( "roRegex", "([$\w]+)\[(\" + Quote() + "[$\w]+\" + Quote() + ")\]\(((?:\w+,?)+)\)$", "" )
    functions = {}
    for each part in body
        '# is this a function?
        if ( funcCall.IsMatch( part ) ) then
            match = funcCall.match(part)
            name = match[1]
            'print( "found secondary function '" + name + "'" )
            if ( functions[name] = invalid ) then
                ' # extract from javascript if not previously done
                functions[name] = extractFunctionFromJS( name, jsText )
            '# else:
            '    # dbg("function '%s' is already in map.", name)
            end if
        else if ( dotCall.IsMatch( part ) ) then
            match = dotcall.match(part)
            name = match[1] + "." + match[2]
            '# don't treat X=A.slice(B) as X=O.F(B)
            if ( match[2] = "slice" OR match[2] = "splice" ) then
                ' Do nothing
            else if ( functions[name] = invalid ) then
                functions[name] = extractDictFuncFromJS( name, jsText )
            end if
        else if ( arrayCall.IsMatch( part ) ) then
            match = arrayCall.match(part)
            name = match[1] + "." + match[2]
            'print "Found array call: " + name
            '# don't treat X=A.slice(B) as X=O.F(B)
            if ( match[2] = "slice" OR match[2] = "splice" ) then
                ' Do nothing
            else if ( functions[name] = invalid ) then
                functions[name] = extractDictFuncFromJS( name, jsText )
            end if
        end if
    next
    return functions
End Function
Function regexEscape( regexPart as String ) as String
    dollarSignRegex = CreateObject( "roRegex", "\$", "" )

    ' Replace escaped quotes
    return dollarSignRegex.ReplaceAll( regexPart, "\\$" )
End Function

Function extractDictFuncFromJS(name as String, jsText as String) as Object
    '""" Find anonymous function from within a dict. """
    'print( "Extracting function '" + name + "' from javascript" )
    dotPos = Instr( 1, name, "." )
    func = {} 
    if ( dotPos > 0 ) then
        var = Left( name, dotPos - 1 )
        fname = Mid( name, dotPos + 1 )
        ' var and fname are not currently escaped properly, in the case of odd characters for regular expressions
        fpattern = CreateObject( "roRegex", "var\s+" + regexEscape( var ) + "\s*\=\s*\{.{0,2000}?" + regexEscape( fname ) + "\:function\(((?:\w+,?)+)\)\{([^}]+)\}", "s" )
        'm = re.search(fpattern % (re.escape(var), re.escape(fname)), js)
        'args, body = m.groups()
        matches = fpattern.Match( jsText )
        if ( matches.Count() > 2 ) then
            args = matches[1]
            body = matches[2]
            'print( "extracted dict function " + name + "(" + args + "){" + body + "};" )
            'func = {'name': name, 'parameters': args.Tokenize(","), 'body': body}
            func.name = name
            func.parameters = args.Tokenize(",")
            func.body = body
        end if
    end if
    return func
End Function

Function getVal(val as String, argsdict as Object) as Dynamic
    '""" resolve variable values, preserve int literals. Return dict."""
    digitRegex = CreateObject( "roRegex", "(\d+)", "" )
    digitMatches = digitRegex.match( val )
    if ( digitMatches.Count() > 1 ) then
        ' Integer Case
        return digitMatches[1].ToInt()
    else if ( argsdict[val] <> invalid ) then
        ' String case
        return argsdict[val]
    else
        print( "Error val: " + val + " from dict" )
    end if
    return invalid
End Function

Function getFuncFromCall(caller as Object, name as String, arguments as Object) as Object
    '"""
    'Return called function complete with called args given a caller function .
    'This function requires that Pafy.funcmap contains the function `name`.
    'It retrieves the function and fills in the parameter values as called in
    'the caller, returning them in the returned newfunction `args` dict
    '"""
    newfunction = getYoutube().funcmap[name]
    newfunction["args"] = {}
    index = 0
    for each arg in arguments
        value = getVal( arg, caller["args"] )
        '# function may not use all arguments
        if (newfunction["parameters"] <> invalid AND index < newfunction["parameters"].Count() ) then
            param = newfunction["parameters"][index]
            newfunction["args"][param] = value
        end if
        index = index + 1
    next
    return newfunction
End Function

Function solve(f, returns=True as Boolean) as Dynamic
    '"""Solve basic javascript function. Return solution value (str). """

    resv = "slice|splice|reverse"

    patterns = getYoutube().patterns

    parts = f["body"].Tokenize( ";" )
    for each part in parts
        ' print("-----------Working on part: " + part)
        ' printaa( f )
        name = ""
        found = false
        for each key in patterns
            name = key
            m = patterns[key].match( part )
            if (m.Count() > 1) then
                'print ( "Invoking : " + key )
                found = true
                exit for
            end if
        next
        if ( found = false ) then
            print( "no match for " + part )
            return invalid
        end if

        if ( name = "split_or_join" ) then
            ' Do nothing
        else if ( name = "func_call_dict") then
            lhs = m[1]
            dic = m[2]
            key = m[3]
            args = m[4]
            funcname = dic + "." + key
            newfunc = getFuncFromCall(f, funcname, args.Tokenize(",") )
            f["args"][lhs] = solve(newfunc)
        else if ( name = "func_call_dict_noret" ) then
            dic = m[1]
            key = m[2]
            args = m[3]
            funcname = dic + "." + key
            newfunc = getFuncFromCall(f, funcname, args.Tokenize(",") )
            changed_args = solve(newfunc, returns=False)
            if ( changed_args <> invalid ) then
                for each arg in f["args"]
                    if ( changed_args[arg] <> invalid ) then
                        f["args"][arg] = changed_args[arg]
                    end if
                next
            end if
        else if ( name = "func_call_array" ) then
            dic = m[1]
            key = m[2]
            args = m[3]
            funcname = dic + "." + key
            newfunc = getFuncFromCall(f, funcname, args.Tokenize(",") )
            changed_args = solve(newfunc, returns=False)
            if ( changed_args <> invalid ) then
                for each arg in f["args"]
                    if ( changed_args[arg] <> invalid ) then
                        f["args"][arg] = changed_args[arg]
                    end if
                next
            end if
        else if ( name = "func_call" ) then
            lhs = m[1]
            funcname = m[2]
            args = m[3]
            newfunc = getFuncFromCall(f, funcname, args.Tokenize(",") )
            f["args"][lhs] = solve(newfunc) ' recursive call
            ' # new var is an index of another var; eg: var a = b[c]
        else if ( name = "x1" ) then
            b = getVal( m[2], f["args"] )
            c = getVal( m[3], f["args"] )
            f["args"][m[1]] = Mid(b, c+1, 1)
        else if ( name = "x2" ) then
            ' # a[b]=c[d%e.length]
            a = getVal( m[1], f["args"] )
            b = getVal( m[2], f["args"] )
            c = getVal( m[3], f["args"] )
            d = getVal( m[4], f["args"] )
            e = getVal( m[5], f["args"] )
            if ( b > 0 ) then
                f["args"][m[1]] = Left(a, b)
            else
                f["args"][m[1]] = ""
            end if
            f["args"][m[1]] =  f["args"][m[1]] + Mid(toStr( c ), (d MOD len(e)) + 1, 1) + Mid(a, b + 2)
        else if ( name = "x3" ) then
            '# a[b]=c
            a = getVal( m[1], f["args"] )
            b = getVal( m[2], f["args"] )
            c = getVal( m[3], f["args"] )
            if ( b > 0 ) then
                f["args"][m[1]] = Left(a, b)
            else
                f["args"][m[1]] = ""
            end if
            f["args"][m[1]] =  f["args"][m[1]] + toStr( c ) + Mid(a, b + 2)
        else if ( name = "x4" ) then
            ' a[b%a.length]=c
            a = getVal( m[1], f["args"] )
            b = getVal( m[2], f["args"] )
            c = getVal( m[3], f["args"] )
            d = getVal( m[4], f["args"] )
            if ( b > 0 ) then
                f["args"][m[1]] = Left(a, b)
            else
                f["args"][m[1]] = ""
            end if
            f["args"][m[1]] =  f["args"][m[1]] + toStr( d ) + Mid(a, b + 2)
        else if ( name = "ret" ) then
            return f["args"][m[1]]
        else if ( name = "reverse" ) then
            f["args"][m[1]] = reverse( getVal(m[2], f["args"]) )
        else if ( name = "reverse_noass" ) then
            f["args"][m[1]] = reverse( getVal(m[1], f["args"]) )
        else if ( name = "splice_noass" ) then
            a = getVal( m[1], f["args"] )
            b = getVal( m[2], f["args"] )
            c = getVal( m[3], f["args"] )
            if ( b = 0 ) then
                f["args"][m[1]] = Mid( a, (b + 1) + c )
            else
                f["args"][m[1]] = Left( a, b ) + Mid( a, (b + 1) + c )
            end if
            'f["args"][m[1]] = Mid( a, (b + 1) + c )
        else if ( name = "return_reverse" ) then
            val = reverse( f["args"][m[1]] )
            return val
        else if ( name = "return_slice" ) then
            a = getVal( m[1], f["args"] )
            b = getVal( m[2], f["args"] )
            return Mid( a, b + 1 )
        else if ( name = "slice" ) then
            a = getVal( m[1], f["args"] )
            b = getVal( m[2], f["args"] )
            c = getVal( m[3], f["args"] )
            f["args"][m[1]] = Mid( b, c + 1 )
        end if
    next

    if ( not( returns ) ) then
        ' # Return the args dict if no return statement in function
        return f["args"]
    else
        print( "Processed js function parts without finding return" )
        return invalid
    end if


End Function

Function reverse(theStr as String) as String
    reversed = []
    strArray = []
    retVal = ""
    for i = 0 to (len( theStr ) - 1)
        strArray[i] = Mid( theStr, i + 1, 1 )
    next
    for each val in strArray
        reversed.Unshift( val )
    next
    for each val in reversed
        retVal = retVal + val
    next
    return retVal
End Function