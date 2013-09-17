
Function Oauth() As Object
    return  m.oa
End Function

'*********************************************************
'**
'** Set up an OAuth object
'**
'*********************************************************
Function InitOauth(appname As String, consumerkey As String, sharedsecret As String, version="1.0" As String) As Object
    this = CreateObject("roAssociativeArray")

    this.sign                    = oauth_sign
    this.prep                    = oauth_prep
    this.addParams               = oauth_add_params
    this.getSignature            = oauth_get_signature
    this.getSignatureBaseString  = oauth_get_signature_base_string

    this.getHmac                 = oauth_get_hmac
    this.initHmac                = oauth_init_hmac
    this.resetHmac               = oauth_reset_hmac

    this.section                 = "Authentication"
    this.items                   = CreateObject("roList")
    this.load                    = loadReg    ' from regScreen.brs
    this.save                    = saveReg    ' from regScreen.brs
    this.erase                   = eraseReg   ' from regScreen.brs
    this.linked                  = definedReg ' from regScreen.brs
    this.dump                    = dumpReg    ' from regScreen.brs

    print "appname: ";appname;" consumerkey: ";consumerkey;" sharedsecret: ";sharedsecret;" version: ";version

    this.appname      = appname
    this.consumerkey  = consumerkey
    this.sharedsecret = sharedsecret
    this.version      = version

    this.items.push("authtoken")
    this.items.push("authsecret")

    this.timestamp = createobject("rotimespan")
    this.datetime  = createobject("rodatetime")

    this.unprotectedkeys = ["oauth_consumer_key", "oauth_nonce", "oauth_signature_method", "oauth_timestamp", "oauth_version" ]
    this.protectedkeys   = ["oauth_consumer_key", "oauth_nonce", "oauth_signature_method", "oauth_timestamp", "oauth_version", "oauth_token"]
    this.verifierkeys    = ["oauth_consumer_key", "oauth_nonce", "oauth_signature_method", "oauth_timestamp", "oauth_version", "oauth_token", "oauth_verifier"]

    this.load()

    return this
End Function


'*********************************************************
'**
'** Initialize message digesters if necessary.
'**
'*********************************************************
Function oauth_init_hmac(key As String) As Dynamic
    hmac = CreateObject("roHMAC")
    key_byte_array = CreateObject("roByteArray")
    key_byte_array.fromAsciiString(key)
    if (hmac.setup("sha1", key_byte_array) <> 0) then
        hmac = invalid
    end if
    return hmac
End Function

Function oauth_get_hmac(protected As Boolean) As Dynamic
    if (protected) then
        name = "hmacProtected"
    else
        name = "hmac"
    end if
    hmac = m[name]
    if (hmac = invalid) then
        key = URLEncode(m.sharedsecret) + "&"
        protectedKey = protected and isnonemptystr(m.authsecret)
        if (protectedKey) then
            key = key + URLEncode(m.authsecret)
        end if
        if (not(protected) OR protectedKey) then
            hmac = m.initHmac(key)
            m[name] = hmac
        end if
    end if
    return hmac
End Function

Function oauth_reset_hmac() As Dynamic
    m.delete("hmacProtected")
    m.delete("hmac")
End Function


'*********************************************************
'**
'** Add Oauth parameters to the HTTP request.
'**
'*********************************************************
Function oauth_add_params(http As Object) As Void
    http.removeParam("oauth_signature")
    m.datetime.mark() 'so that m.datetime.asSeconds() retrieves the current time
    keyvalues = [ m.consumerkey, itostr(rnd(999999999)), "HMAC-SHA1", itostr(m.datetime.asSeconds()), m.version ]
    if (http.accessVerifier) then
        keyvalues.push(m.authtoken)
        keyvalues.push(m.verifier)
        http.addallparams(m.verifierkeys, keyvalues, "urlParams")
    else if (http.protected) then
        keyvalues.push(m.authtoken)
        http.addallparams(m.protectedkeys, keyvalues, "urlParams")
    else
        http.addallparams(m.unprotectedkeys, keyvalues, "urlParams")
    end if
End Function


'*********************************************************
'**
'** adds appropriate params and signature
'** via callback on the http object
'** allows just-before-send signature
'** so timestamp is correct on previously
'** composed requests
'**
'*********************************************************
Function Oauth_Callback_Prep()
    ' called on an http object
    Oauth().prep(m)
End Function


'*********************************************************
'**
'** adds appropriate params and signature
'**
'*********************************************************
Function oauth_prep(http As Object)
    m.addParams(http)
    signature = m.getSignature(http)
    http.addParam("oauth_signature", signature, "urlParams")
End Function


'*********************************************************
'**
'** adds appropriate params and signature
'**
'*********************************************************
Function oauth_sign(http As Object, protected=true As Boolean, accessVerifier=false As Boolean)
    http.callbackPrep = Oauth_Callback_Prep ' defer until go()
    http.protected = protected
    http.accessVerifier = accessVerifier
End Function


'*********************************************************
'*********************************************************
Function oauth_get_signature_base_string(httpObj As Object) as String
    sig_base_str =  URLEncode(UCase(httpObj.method))
    sig_base_str = sig_base_str + "&" + URLEncode(httpObj.base)

    params = httpObj.GetParams("urlParams")

    if (not(params.empty())) then
        sig_base_str = sig_base_str + "&" + UrlEncode(params.encode())
    end if

    'print "oauth signature base string: "; sig_base_str
    return sig_base_str
End Function


'*********************************************************
'**
'** @returns The Oauth signature which is computed from
'**          the HTTP method and HTTP parameters.
'**
'*********************************************************
Function oauth_get_signature(httpObj As Object) as String
    hmac = m.getHmac(httpObj.protected)
    if (hmac <> invalid) then
        sig_base_str = m.getSignatureBaseString(httpObj)
        sig_base_byte_array = CreateObject("roByteArray")
        sig_base_byte_array.fromAsciiString(sig_base_str)
        result = hmac.process(sig_base_byte_array)
        return result.toBase64String()
    else
        print "HMAC setup error"
        return ""
    end if
End Function

