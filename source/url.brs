
' ******************************************************
'
' Url Query builder
'
' To aid in percent-encoding url query parameters.
' In theory you can blindly encode the whole query (including ='s, &'s, etc)
'
' so this is a quick and dirty name/value encoder/accumulator
'
' The oauth protocol needs to interact with parameters in a
' particular way, so access to groups of parameters and
' their encodings are provided as well.
'
' Several callbacks can be placed on the returned http object
' by the calling code to be called by this code when appropriate:
' callbackPrep - called right before sending
' callbackRetry - called after failure if retries>0
' callbackCancel - called after failure if retries=0
' These allow side effects without explicitly coding them here.
' ******************************************************

Function NewHttp(url As String, rawQueryString=invalid as Dynamic, port=invalid As Dynamic, method="GET" As String) as Object
    this                           = CreateObject("roAssociativeArray")
    this.port                      = port
    this.method                    = method
    this.anchor                    = ""
    this.label                     = "init"
    this.timeout                   = 5000 ' 5 secs
    this.retries                   = 1
    this.timer                     = CreateObject("roTimespan")
    this.timestamp                 = CreateObject("roTimespan")

    'computed accessors
    this.Parse                     = http_parse
    this.AddParam                  = http_add_param
    this.AddAllParams              = http_add_all_param
    this.RemoveParam               = http_remove_param
    this.GetURL                    = http_get_url
    this.GetParams                 = http_get_params
    this.ParamGroup                = http_get_param_group
    this.AddRawQuery               = http_add_raw_query

    'transfers
    this.GetToStringWithRetry      = http_get_to_string_with_retry
    this.GetToStringWithTimeout    = http_get_to_string_with_timeout
    this.PostFromStringWithTimeout = http_post_from_string_with_timeout

    this.Go                        = http_go
    this.Ok                        = http_ok
    this.Sync                      = http_sync
    this.Receive                   = http_receive
    this.Cancel                    = http_cancel
    this.CheckTimeout              = http_check_timeout
    this.Retry                     = http_retry

    'internal
    this.Prep                      = http_prep
    this.Wait                      = http_wait_with_timeout
    this.Dump                      = http_dump
    if (rawQueryString <> invalid) then
        this.raw_query = rawQueryString
    end if
    this.Parse(url)

    return this
End Function

' ******************************************************
'
' Setup the underlying http transfer object.
'
' ******************************************************

Function http_prep(method="" As String)
    ' this callback allows just-before-send
    ' mods to the request, e.g. timestamp
    if (isfunc(m.callbackPrep)) then
        m.callbackPrep()
    end if
    m.status  = 0
    m.response = ""
    urlobj = CreateObject("roUrlTransfer")
    if (type(m.port) <> "roMessagePort") then
        m.port = CreateObject("roMessagePort")
    end if
    urlobj.SetPort(m.port)
    urlobj.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ' Wrap in an eval() block to catch any potential errors.
    eval( "urlobj.SetCertificatesDepth( 3 )" )
    urlobj.EnableEncodings(true)
    urlobj.AddHeader("Expect","")
    'urlobj.RetainBodyOnError(true)
    url = m.GetUrl()
    urlobj.SetUrl(url)
    if (m.method <> "" AND m.method <> method) then
        m.method = method
    end if
    urlobj.SetRequest(m.method)
    HttpActive().replace(m,urlobj)
    m.timer.mark()
End Function

Function http_add_raw_query(query As String) as Void
    m.raw_query = query
End Function

' ******************************************************
'
' Parse an url string into components of this object
'
' ******************************************************

Function http_parse(url As String) as Void
    remnant = CreateObject("roString")
    remnant.SetString(url)

    anchorBegin = Instr(1, remnant, "#")
    if (anchorBegin > 0) then
        if (anchorBegin < Len(remnant)) then
            m.anchor = Mid(remnant,anchorBegin + 1)
        end if
        remnant = Left(remnant,anchorbegin - 1)
    end if

    paramBegin = Instr(1, remnant, "?")
    if (paramBegin > 0) then
        if (paramBegin < Len(remnant)) then
            m.GetParams("urlParams").parse(Mid(remnant,paramBegin+1))
        end if
        remnant = Left(remnant,paramBegin - 1)
    end if

    m.base = remnant
End Function

' ******************************************************
'
' Add an URL parameter to this object
'
' ******************************************************

Function http_add_param(name As String, val As String, group="" As String)
    params = m.GetParams(group)
    params.add(name,val)
End Function


Function http_add_all_param(keys as object, vals as object, group="" As String)
    params = m.GetParams(group)
    params.addall(keys,vals)
End Function

' ******************************************************
'
' remove an URL parameter from this object
'
' ******************************************************

Function http_remove_param(name As String, group="" As String)
    params = m.GetParams(group)
    params.remove(name)
End Function

' ******************************************************
'
' Get a named parameter list from this object
'
' ******************************************************

Function http_get_params(group="" As String)
    name = m.ParamGroup(group)
    if (not(m.DoesExist(name))) then
        m[name] = NewUrlParams()
    end if
    return m[name]
End Function

' ******************************************************
'
' Return the full encoded URL.
'
' ******************************************************

Function http_get_url() As String
    url = m.base
    if (m.raw_query <> invalid) then
        url = url + m.raw_query
    else
        params = m.GetParams("urlParams")
        if (not(params.empty())) then
            url = url + "?"
        end if
        url = url + params.encode()
    end if
    if (m.anchor <> "") then
        url = url + "#" + m.anchor
    end if
    return url
End Function

' ******************************************************
'
' Return the parameter group name,
' correctly defaulted if necessary.
'
' ******************************************************

Function http_get_param_group(group="" as String)
    if (group = "") then
        if (m.method = "POST") then
            name = "bodyParams"
        else
            name = "urlParams"
        end if
    else
        name = group
    end if
    return name
End Function

' ******************************************************
'
' Performs Http.AsyncGetToString() in a retry loop
' with exponential backoff. To the outside
' world this appears as a synchronous API.
'
' Return empty string on timeout
'
' ******************************************************

Function http_get_to_string_with_retry() as String

    timeout%         = 2
    num_retries%     = 5

    while (num_retries% > 0)
        ' print "Http: get tries left " + itostr(num_retries%)
        m.Prep("GET")
        if (m.Http.AsyncGetToString()) then
            if (m.Wait(timeout%)) then
                exit while
            end if
            timeout% = 2 * timeout%
        end if
        num_retries% = num_retries% - 1
    end while

    return m.response
End Function

' ******************************************************
'
' Performs Http.AsyncGetToString() with a single timeout in seconds
' To the outside world this appears as a synchronous API.
'
' Return empty string on timeout
'
' ******************************************************

Function http_get_to_string_with_timeout(seconds as Integer, headers=invalid As Object) as String
    if (m.method = invalid) then
        m.method = "GET"
    end if
    m.Prep(m.method)

    if (headers <> invalid) then
        for each key in headers
            print key,headers[key]
            m.Http.AddHeader(key, headers[key])
        end for
    end if

    if (m.Http.AsyncGetToString()) then
        m.Wait(seconds)
    end if
    return m.response
End Function

' ******************************************************
'
' Performs Http.AsyncPostFromString() with a single timeout in seconds
' To the outside world this appears as a synchronous API.
'
' Return empty string on timeout
'
' ******************************************************

Function http_post_from_string_with_timeout(val As String, seconds as Integer, headers=invalid As Object) as String
    if (m.method = invalid) then
        m.method = "POST"
    end if
    m.Prep(m.method)

    if (headers <> invalid) then
        for each key in headers
            print key,headers[key]
            m.Http.AddHeader(key, headers[key])
        end for
    end if

    if (m.Http.AsyncPostFromString(val)) then
        m.Wait(seconds)
    end if
    return m.response
End Function

' ******************************************************
'
' Common wait() for all the synchronous http transfers
'
' ******************************************************

Function http_wait_with_timeout(seconds As Integer) As Boolean
    id = HttpActive().ID(m)
    while (m.status = 0)
        nextTimeout = 1000 * seconds - m.timer.TotalMilliseconds()
        if (seconds > 0 AND nextTimeout <= 0) then
            exit while
        end if
        event = wait(nextTimeout, m.Http.GetPort())
        if (type(event) = "roUrlEvent") then
            HttpActive().receive(event)
        else if (event = invalid) then
            m.cancel()
        else
            print "Http: unhandled event "; type(event)
        end if
    end while
    HttpActive().removeID(id)
    m.Dump()
    return m.Ok()
End Function

Function http_receive(msg As Object)
    m.status = msg.GetResponseCode()
    m.response = msg.GetString()
    m.label = "done"
End Function

Function http_cancel()
    m.Http.AsyncCancel()
    m.status = -1
    m.label = "cancel"
    m.dump()
    HttpActive().remove(m)
End Function

Function http_go(method="" As String) As Boolean
    ok = false
    m.Prep(method)
    if (m.method = "POST" OR m.method = "PUT") then
        ok = m.http.AsyncPostFromString(m.getParams().encode())
    else if (m.method = "GET" OR m.method = "DELETE" OR m.method = "")
        ok = m.http.AsyncGetToString()
    else
        print "Http: "; m.method; " is not supported"
    end if
    m.label = "sent"
    'm.Dump()
    return ok
End Function

Function http_ok() As Boolean
    ' depends on m.status which is updated by m.Wait()
    statusGroup = int(m.status/100)
    return statusGroup=2 or statusGroup=3
End Function

Function http_sync(seconds As Integer) As Boolean
    if (m.Go()) then
        m.Wait(seconds)
    end if
    return m.Ok()
End Function

Function http_dump()
    time = "unknown"
    if (m.DoesExist("timer")) then
        time = itostr(m.timer.TotalMilliseconds())
    end if
    print "Http: #"; m.Http.GetIdentity(); " "; m.label; " status:"; m.status; " time: "; time; "ms request: "; m.method; " "; m.Http.GetURL()
    if (not(m.GetParams("bodyParams").empty())) then
        print "  body: "; m.GetParams("bodyParams").encode()
    end if
End Function

Function http_check_timeout(defaultTimeout=0 As Integer) As Integer
    timeLeft = m.timeout-m.timer.TotalMilliseconds()
    if (timeLeft <= 0) then
        m.retry()
        timeLeft = defaultTimeout
    end if
    return timeLeft
End Function

Function http_retry(defaultTimeout=0 As Integer) As Integer
    m.cancel()
    if (m.retries > 0) then
        m.retries = m.retries - 1
        if (isfunc(m.callbackRetry)) then
            m.callbackRetry()
        else
            m.go()
        end if
    else if (isfunc(m.callbackCancel)) then
        m.callbackCancel()
    end if
End Function

' ******************************************************
'
' Operations on a collection of URL parameters
'
' ******************************************************

Function NewUrlParams(encoded="" As String, separator="&" As String) As Object
    'stores the unencoded parameters in sorted order
    this                           = CreateObject("roAssociativeArray")
    this.names                     = CreateObject("roArray",0,true)
    this.params                    = CreateObject("roAssociativeArray")
    this.params.SetModeCaseSensitive()

    this.encode                    = params_encode
    this.parse                     = params_parse
    this.add                       = params_add
    this.addReplace                = params_add_replace
    this.addAll                    = params_add_all
    this.remove                    = params_remove
    this.empty                     = params_empty
    this.get                       = params_get
    this.separator                 = separator
    this.parse(encoded)
    return this
End Function

Function params_encode() As String
    encodedParams = ""
    m.names.reset()
    while (m.names.isNext())
        name = m.names.Next()
        encodedParams = encodedParams + URLEncode(name) + "=" + URLEncode(m.params[name])
        if (m.names.isNext()) then
            encodedParams = encodedParams + m.separator
        end if
    end while
    return encodedParams
End Function

Function params_parse(encoded_params As String) as Object
    params = strTokenize(encoded_params,m.separator)
    for each paramExpr in params
        param = strTokenize(paramExpr,"=")
        if (param.Count() = 2) then
            m.addReplace(UrlDecode(param[0]),UrlDecode(param[1]))
        end if
    end for
    return m
End Function

Function params_add(name As String, val As String) as Object
    if (not(m.params.DoesExist(name))) then
        SortedInsert(m.names, name)
        m.params[name] = val
    end if
    return m
End Function

Function params_add_replace(name As String, val As String) as Object
    if (m.params.DoesExist(name)) then
        m.params[name] = val
    else
        m.add(name,val)
    end if
    return m
End Function

Function params_add_all(keys as Object, vals as object) as Object
' keys is an array
' vals is an array
    i = 0
    for each name in keys
        if (not(m.params.DoesExist(name))) then
            m.names.push(name)
        end if
        m.params[name] = vals[i]
        i = i + 1
    end for
    QuickSort(m.names)
    return m
End Function

sub params_remove(name As String)
    if (m.params.delete(name)) then
        n = 0
        while (n < m.names.count())
            if (name = m.names[n]) then
                m.names.delete(n)
                return
            end if
            n = n + 1
        end while
    end if
End sub

Function params_empty() as Boolean
    return (m.params.IsEmpty())
End Function

Function params_get(name As String) as String
    return validstr(m.params[name])
End Function


' ******************************************************
'
' URLEncode - strict URL encoding of a string
'
' ******************************************************

Function URLEncode(str As String) As String
    if (not(m.DoesExist("encodeProxyUrl"))) then
        m.encodeProxyUrl = CreateObject("roUrlTransfer")
    end if
    return m.encodeProxyUrl.urlEncode(str)
End Function

' ******************************************************
'
' URLDecode - strict URL decoding of a string
'
' ******************************************************

Function URLDecode(str As String) As String
    strReplace(str,"+"," ") ' backward compatibility
    if (not(m.DoesExist("encodeProxyUrl"))) then
        m.encodeProxyUrl = CreateObject("roUrlTransfer")
    end if
    return m.encodeProxyUrl.Unescape(str)
End Function

'
' map of identity to active http objects
'
Function HttpActive() As Object
    ' singleton factory
    ha = m.HttpActive
    if (ha = invalid) then
        ha = CreateObject("roAssociativeArray")
        ha.actives          = CreateObject("roAssociativeArray")
        ha.icount           = 0
        ha.defaultTimeout   = 30000 ' 30 secs
        ha.checkTimeouts    = http_active_checkTimeouts
        ha.count            = http_active_count
        ha.receive          = http_active_receive
        ' by http obj
        ha.id               = http_active_id
        ha.add              = http_active_add
        ha.remove           = http_active_remove
        ha.replace          = http_active_replace
        ' by ID
        ha.getID            = http_active_getID
        ha.removeID         = http_active_removeID
        ha.total            = strtoi(validstr(RegRead("Http.total","Debug")))
        m.HttpActive        = ha
    end if
    return ha
End Function

Function http_active_count() As Dynamic
    return m.icount
End Function

Function http_active_receive(msg As Object) As Dynamic
    id = msg.GetSourceIdentity()
    http = m.getID(id)
    if (http <> invalid) then
        http.receive(msg)
    else
        print "Http: #"; id; " discarding unidentifiable http response"
        print "Http: #"; id; " status"; msg.GetResponseCode()
        print "Http: #"; id; " response"; chr(10); msg.GetString()
    end if
    return http
end Function

Function http_active_id(http As Object) As Dynamic
    id = invalid
    if (http.DoesExist("http")) then
        id = http.http.GetIdentity()
    end if
    'print "Http: got identity #"; id
    return id
End Function

Function http_active_add(http As Object)
    id = m.ID(http)
    if (id <> invalid) then
        'print "Http: #"; id; " adding to active"
        m.actives[itostr(id)] = http
        m.icount = m.icount + 1
        m.total = m.total + 1
        if (wrap(m.total,50) = 0) then
            RegWrite("Http.total",itostr(m.total),"Debug")
            print "Http: total requests"; m.total
        end if
    end if
End Function

Function http_active_remove(http As Object)
    id = m.ID(http)
    if (id <> invalid) then 
        m.removeID(id)
    end if
End Function

Function http_active_replace(http As Object, urlXfer As Object)
    m.remove(http)
    http.http = urlXfer
    m.add(http)
End Function

Function http_active_getID(id As Integer) As Dynamic
    return m.actives[itostr(id)]
End Function

Function http_active_removeID(id As Integer)
    strID = itostr(id)
    if (m.actives.DoesExist(strID)) then
        'print "Http: #"; id; " removing from active"
        m.actives.delete(strID)
        m.icount = m.icount -1
    end if
End Function

Function http_active_checkTimeouts() As Integer
    defaultTimeout = m.defaultTimeout
    timeLeft = defaultTimeout
    for each id in m.actives
        active = m.actives[id]
        activeTL = active.checkTimeout(defaultTimeout)
        if (activeTL<timeLeft) then
            timeLeft = activeTL
        end if
    end for
    return timeLeft
End Function

