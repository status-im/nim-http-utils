import std/strutils,
  unittest2,
  ../httputils

# Some tests are borrowed from
# https://github.com/nodejs/http-parser/blob/master/test.c

const RequestVectors = [
  "GET /test HTTP/1.1\r\n" &
    "User-Agent: curl/7.18.0 (i486-pc-linux-gnu) libcurl/7.18.0 OpenSSL/0.9.8g zlib/1.2.3.3 libidn/1.1\r\n" &
    "Host: 0.0.0.0=5000\r\n" &
    "Accept: */*\r\n" &
    "\r\n",
  "GET /favicon.ico HTTP/1.1\r\n" &
    "Host: 0.0.0.0=5000\r\n" &
    "User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008061015 Firefox/3.0\r\n" &
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" &
    "Accept-Language: en-us,en;q=0.5\r\n" &
    "Accept-Encoding: gzip,deflate\r\n" &
    "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n" &
    "Keep-Alive: 300\r\n" &
    "Connection: keep-alive\r\n" &
    "\r\n",
  "GET /dumbfuck HTTP/1.1\r\n" &
    "aaaaaaaaaaaaa:++++++++++\r\n" &
    "\r\n",
  "GET /forums/1/topics/2375?page=1#posts-17408 HTTP/1.1\r\n" &
    "\r\n",
  "GET /get_no_headers_no_body/world HTTP/1.0\r\n" &
    "\r\n",
  "POST /get_one_header_no_body HTTP/2.0\r\n" &
    "Accept: */*\r\n" &
    "\r\n",
  "GET /get_funky_content_length_body_hello HTTP/1.0\r\n" &
    "conTENT-Length: 5\r\n" &
    "\r\n",
  "POST /post_identity_body_world?q=search#hey HTTP/1.1\r\n" &
    "Accept: */*\r\n" &
    "Transfer-Encoding: identity\r\n" &
    "Content-Length: 5\r\n" &
    "\r\n",
  "GET /with_\"stupid\"_quotes?foo=\"bar\" HTTP/1.1\r\n\r\n",
  "CONNECT foo.bar.com:443 HTTP/1.0\r\n" &
    "User-agent: Mozilla/1.1N\r\n" &
    "Proxy-authorization: basic aGVsbG86d29ybGQ=\r\n" &
    "Content-Length: 10\r\n" &
    "\r\n",
  "PUT /!#$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~ HTTP/1.1\r\n" &
    "Host: example.com\r\n" &
    "Connection: Upgrade\r\n" &
    "Upgrade: HTTP/2.0\r\n" &
    "Content-Length: 15\r\n" &
    "\r\n",
  "GET / HTTP/1.0\r\n\r\n",
  "POST / HTTP/1.0\r\n\r\n",
  "PUT / HTTP/1.0\r\n\r\n",
  "PATCH / HTTP/1.0\r\n\r\n",
  "DELETE / HTTP/1.0\r\n\r\n",
  "OPTIONS / HTTP/1.0\r\n\r\n",
  "TRACE / HTTP/1.0\r\n\r\n",
  "CONNECT / HTTP/1.0\r\n\r\n",
  "CONNECT / HTTP/2.0\r\n" &
    "!#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~: !#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~\r\n" &
    "\r\n",
  "POST /empty_header HTTP/1.1\r\n" &
    "Server: \r\n" &
    "Accept: */*\r\n" &
    "\r\n",
  "TRACE / HTTP/1.1\r\n" &
    "Server: \r\n" &
    "\r\n",
  "GET / HTTP/0.9\r\n" &
    "Content-Length: 99223372036854775807\r\n" &
    "\r\n",
  "POST / HTTP/1.1\r\n" &
    "Host:example.amazonaws.com\r\n" &
    "X-Amz-Date:20150830T123600Z\r\n\r\nhello",
  "GET /%E1%88%B4 HTTP/1.1\r\n" &
    "Host:example.amazonaws.com\r\n" &
    "X-Amz-Date:20150830T123600Z\r\n\r\n",
  "GET / HTTP/1.1\r\n" &
    "Sec-Fetch-User: ?1\r\n" &
    "Sec-Fetch-Mode:@1\r\n\r\n"
]

const RequestHeaderTexts = [
  (k: "User-Agent", v: "curl/7.18.0 (i486-pc-linux-gnu) libcurl/7.18.0 OpenSSL/0.9.8g zlib/1.2.3.3 libidn/1.1"),
  (k: "Host", v: "0.0.0.0=5000"),
  (k: "Accept", v: "*/*"),

  (k: "Host", v: "0.0.0.0=5000"),
  (k: "User-Agent", v: "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008061015 Firefox/3.0"),
  (k: "Accept", v: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"),
  (k: "Accept-Language", v: "en-us,en;q=0.5"),
  (k: "Accept-Encoding", v: "gzip,deflate"),
  (k: "Accept-Charset", v: "ISO-8859-1,utf-8;q=0.7,*;q=0.7"),
  (k: "Keep-Alive", v: "300"),
  (k: "Connection", v: "keep-alive"),

  (k: "aaaaaaaaaaaaa", v: "++++++++++"),

  (k: "Accept", v: "*/*"),

  (k: "Content-Length", v: "5"),

  (k: "Accept", v: "*/*"),
  (k: "Transfer-Encoding", v: "identity"),
  (k: "Content-Length", v: "5"),

  (k: "User-agent", v: "Mozilla/1.1N"),
  (k: "Proxy-authorization", v: "basic aGVsbG86d29ybGQ="),
  (k: "Content-Length", v: "10"),

  (k: "Host", v: "example.com"),
  (k: "Connection", v: "Upgrade"),
  (k: "Upgrade", v: "HTTP/2.0"),
  (k: "Content-Length", v: "15"),

  (k: "!#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~", v: "!#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~"),

  (k: "Server", v: ""),
  (k: "Accept", v: "*/*"),

  (k: "Server", v: ""),

  (k: "Content-Length", v: "99223372036854775807"),

  (k: "Host", v: "example.amazonaws.com"),
  (k: "X-Amz-Date", v: "20150830T123600Z"),

  (k: "Host", v: "example.amazonaws.com"),
  (k: "X-Amz-Date", v: "20150830T123600Z"),

  (k: "Sec-Fetch-User", v: "?1"),
  (k: "Sec-Fetch-Mode", v: "@1")
]

const RequestResults = [
  0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0xC2, 0x8E, 0x8E,
  0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E, 0x8E,
  0x8E, 0x8E, 0x8E, 0x8E
]

const RequestHeaders = [
  (0, 2), (3, 10), (11, 11), (0, -1), (0, -1), (12, 12), (13, 13), (14, 16),
  (0, -1), (17, 19), (20, 23), (0, -1), (0, -1), (0, -1), (0, -1), (0, -1),
  (0, -1), (0, -1), (0, -1), (24, 24), (25, 26), (27, 27), (28, 28), (29, 30),
  (31, 32), (33, 34)
]

const RequestVersions = [
  HttpVersion11, HttpVersion11, HttpVersion11, HttpVersion11, HttpVersion10,
  HttpVersion20, HttpVersion10, HttpVersion11, HttpVersion11, HttpVersion10,
  HttpVersion11, HttpVersion10, HttpVersion10, HttpVersion10, HttpVersion10,
  HttpVersion10, HttpVersion10, HttpVersion10, HttpVersion10, HttpVersion20,
  HttpVersion11, HttpVersion11, HttpVersion09, HttpVersion11, HttpVersion11,
  HttpVersion11
]

const RequestUris = [
  "/test", "/favicon.ico", "/dumbfuck", "/forums/1/topics/2375?page=1#posts-17408",
  "/get_no_headers_no_body/world", "/get_one_header_no_body",
  "/get_funky_content_length_body_hello", "/post_identity_body_world?q=search#hey",
  "/with_\"stupid\"_quotes?foo=\"bar\"", "foo.bar.com:443",
  "/!#$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~",
  "/", "/", "/", "/", "/", "/", "/", "/", "/", "/empty_header", "/", "/", "/",
  "/%E1%88%B4", "/"
]

const RequestCLengths = [
  0, 0, 0, 0, 0, 0, 5, 5, -1, 10, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0,
  0
]

const ResponseVectors = [
  "HTTP/1.1 301 Moved Permanently\r\n" &
    "Location: http://www.google.com/\r\n" &
    "Content-Type: text/html; charset=UTF-8\r\n" &
    "Date: Sun, 26 Apr 2009 11:11:49 GMT\r\n" &
    "Expires: Tue, 26 May 2009 11:11:49 GMT\r\n" &
    "X-$PrototypeBI-Version: 1.6.0.3\r\n" &
    "Cache-Control: public, max-age=2592000\r\n" &
    "Server: gws\r\n" &
    "Content-Length:  219  \r\n" &
    "\r\n",
  "HTTP/1.0 200 OK\r\n" &
    "Date: Tue, 04 Aug 2009 07:59:32 GMT\r\n" &
    "Server: Apache\r\n" &
    "X-Powered-By: Servlet/2.5 JSP/2.1\r\n" &
    "Content-Type: text/xml; charset=utf-8\r\n" &
    "Connection: close\r\n" &
    "\r\n",
  "HTTP/1.1 404 Not Found\r\n\r\n",
  "HTTP/1.1 503\r\n\r\n",
  "HTTP/1.1 200 OK\n",
  "HTTP/1.1 200 OK\r\n" &
    "Server: DCLK-AdSvr\r\n" &
    "Content-Type: text/xml\r\n" &
    "Content-Length: 0\r\n" &
    "DCLK_imp: v7;x;114750856;0-0;0;17820020;0/0;21603567/21621457/1;;~okv=;dcmt=text/xml;;~cs=o\r\n" &
    "\r\n",
  "HTTP/1.0 301 Moved Permanently\r\n" &
    "Date: Thu, 03 Jun 2010 09:56:32 GMT\r\n" &
    "Server: Apache/2.2.3 (Red Hat)\r\n" &
    "Cache-Control: public\r\n" &
    "Pragma: \r\n" &
    "Location: http://www.bonjourmadame.fr/\r\n" &
    "Vary: Accept-Encoding\r\n" &
    "Content-Length: 0\r\n" &
    "Content-Type: text/html; charset=UTF-8\r\n" &
    "Connection: keep-alive\r\n" &
    "\r\n",
  "HTTP/1.1 200 OK\r\n" &
    "Date: Tue, 28 Sep 2010 01:14:13 GMT\r\n" &
    "Server: Apache\r\n" &
    "Cache-Control: no-cache, must-revalidate\r\n" &
    "Expires: Mon, 26 Jul 1997 05:00:00 GMT\r\n" &
    ".et-Cookie: PlaxoCS=1274804622353690521; path=/; domain=.plaxo.com\r\n" &
    "Vary: Accept-Encoding\r\n" &
    "_eep-Alive: timeout=45\r\n" &
    "_onnection: Keep-Alive\r\n" &
    "Transfer-Encoding: chunked\r\n" &
    "Content-Type: text/html\r\n" &
    "Connection: close\r\n" &
    "\r\n",
  "HTTP/1.1 301 MovedPermanently\r\n" &
    "Date: Wed, 15 May 2013 17:06:33 GMT\r\n" &
    "Server: Server\r\n" &
    "x-amz-id-1: 0GPHKXSJQ826RK7GZEB2\r\n" &
    "p3p: policyref=\"http://www.amazon.com/w3c/p3p.xml\",CP=\"CAO DSP LAW CUR ADM IVAo IVDo CONo OTPo OUR DELi PUBi OTRi BUS PHY ONL UNI PUR FIN COM NAV INT DEM CNT STA HEA PRE LOC GOV OTC \"\r\n" &
    "x-amz-id-2: STN69VZxIFSz9YJLbz1GDbxpbjG6Qjmmq5E3DxRhOUw+Et0p4hr7c/Q8qNcx4oAD\r\n" &
    "Location: http://www.amazon.com/Dan-Brown/e/B000AP9DSU/ref=s9_pop_gw_al1?_encoding=UTF8&refinementId=618073011&pf_rd_m=ATVPDKIKX0DER&pf_rd_s=center-2&pf_rd_r=0SHYY5BZXN3KR20BNFAY&pf_rd_t=101&pf_rd_p=1263340922&pf_rd_i=507846\r\n" &
    "Vary: Accept-Encoding,User-Agent\r\n" &
    "Content-Type: text/html; charset=ISO-8859-1\r\n" &
    "Transfer-Encoding: chunked\r\n" &
    "\r\n",
  "HTTP/2.0 200 Success\r\n" &
    "!#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~: !#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~\r\n" &
    "\r\n",
  "HTTP/0.9 200\r\n" &
    "Content-Length: 15\r\n" &
    "\r\n",
  "HTTP/0.9 200\r\n" &
    "Content-Length: 99223372036854775807\r\n" &
    "\r\n",
  "HTTP/1.1 200 \r\n" &
    "content-length: 458\r\n" &
    "\r\n"
]

const ResponseHeaderTexts = [
  (k: "Location", v: "http://www.google.com/"),
  (k: "Content-Type", v: "text/html; charset=UTF-8"),
  (k: "Date", v: "Sun, 26 Apr 2009 11:11:49 GMT"),
  (k: "Expires", v: "Tue, 26 May 2009 11:11:49 GMT"),
  (k: "X-$PrototypeBI-Version", v: "1.6.0.3"),
  (k: "Cache-Control", v: "public, max-age=2592000"),
  (k: "Server", v: "gws"),
  (k: "Content-Length", v: "219  "),

  (k: "Date", v: "Tue, 04 Aug 2009 07:59:32 GMT"),
  (k: "Server", v: "Apache"),
  (k: "X-Powered-By", v: "Servlet/2.5 JSP/2.1"),
  (k: "Content-Type", v: "text/xml; charset=utf-8"),
  (k: "Connection", v: "close"),

  (k: "Server", v: "DCLK-AdSvr"),
  (k: "Content-Type", v: "text/xml"),
  (k: "Content-Length", v: "0"),
  (k: "DCLK_imp", v: "v7;x;114750856;0-0;0;17820020;0/0;21603567/21621457/1;;~okv=;dcmt=text/xml;;~cs=o"),

  (k: "Date", v: "Thu, 03 Jun 2010 09:56:32 GMT"),
  (k: "Server", v: "Apache/2.2.3 (Red Hat)"),
  (k: "Cache-Control", v: "public"),
  (k: "Pragma", v: ""),
  (k: "Location", v: "http://www.bonjourmadame.fr/"),
  (k: "Vary", v: "Accept-Encoding"),
  (k: "Content-Length", v: "0"),
  (k: "Content-Type", v: "text/html; charset=UTF-8"),
  (k: "Connection", v: "keep-alive"),

  (k: "Date", v: "Tue, 28 Sep 2010 01:14:13 GMT"),
  (k: "Server", v: "Apache"),
  (k: "Cache-Control", v: "no-cache, must-revalidate"),
  (k: "Expires", v: "Mon, 26 Jul 1997 05:00:00 GMT"),
  (k: ".et-Cookie", v: "PlaxoCS=1274804622353690521; path=/; domain=.plaxo.com"),
  (k: "Vary", v: "Accept-Encoding"),
  (k: "_eep-Alive", v: "timeout=45"),
  (k: "_onnection", v: "Keep-Alive"),
  (k: "Transfer-Encoding", v: "chunked"),
  (k: "Content-Type", v: "text/html"),
  (k: "Connection", v: "close"),

  (k: "Date", v: "Wed, 15 May 2013 17:06:33 GMT"),
  (k: "Server", v: "Server"),
  (k: "x-amz-id-1", v: "0GPHKXSJQ826RK7GZEB2"),
  (k: "p3p", v: "policyref=\"http://www.amazon.com/w3c/p3p.xml\",CP=\"CAO DSP LAW CUR ADM IVAo IVDo CONo OTPo OUR DELi PUBi OTRi BUS PHY ONL UNI PUR FIN COM NAV INT DEM CNT STA HEA PRE LOC GOV OTC \""),
  (k: "x-amz-id-2", v: "STN69VZxIFSz9YJLbz1GDbxpbjG6Qjmmq5E3DxRhOUw+Et0p4hr7c/Q8qNcx4oAD"),
  (k: "Location", v: "http://www.amazon.com/Dan-Brown/e/B000AP9DSU/ref=s9_pop_gw_al1?_encoding=UTF8&refinementId=618073011&pf_rd_m=ATVPDKIKX0DER&pf_rd_s=center-2&pf_rd_r=0SHYY5BZXN3KR20BNFAY&pf_rd_t=101&pf_rd_p=1263340922&pf_rd_i=507846"),
  (k: "Vary", v: "Accept-Encoding,User-Agent"),
  (k: "Content-Type", v: "text/html; charset=ISO-8859-1"),
  (k: "Transfer-Encoding", v: "chunked"),

  (k: "!#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~", v: "!#$%&'*+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~"),

  (k: "Content-Length", v: "15"),

  (k: "Content-Length", v: "99223372036854775807"),

  (k: "Content-Length", v: "458")
]

const ResponseResults = [ 0x9F, 0x9F, 0x9F, 0x9F, 0xC3, 0x9F, 0x9F, 0x9F, 0x9F,
                          0x9F, 0x9F, 0x9F, 0x9F ]

const ResponseHeaders = [ (0, 7), (8, 12), (0, -1), (0, -1), (0, -1), (13, 16),
                          (17, 25), (26, 36), (37, 45), (46, 46), (47, 47),
                          (48, 48), (49, 49)]

const ResponseVersions = [HttpVersion11, HttpVersion10, HttpVersion11,
                          HttpVersion11, HttpVersion11, HttpVersion11,
                          HttpVersion10, HttpVersion11, HttpVersion11,
                          HttpVersion20, HttpVersion09, HttpVersion09,
                          HttpVersion11]

const ResponseCodes = [301, 200, 404, 503, 200, 200, 301, 200, 301, 200, 200,
                       200, 200]

const ResponseReasons = ["Moved Permanently", "OK", "Not Found", "", "", "OK",
                         "Moved Permanently", "OK", "MovedPermanently",
                         "Success", "", "", ""]
const ResponseCLengths = [ 219, 0, 0, 0, -1, 0, 0, 0, 0, 0, 15, -1, 458]

suite "HTTP Procedures test suite":
  test "HTTP Request Vectors":
    for i in 0..<len(RequestVectors):
      var a = cast[seq[char]](RequestVectors[i])
      var req = parseRequest(a)
      if RequestResults[i] == 0x8E:
        check:
          req.success() == true
          req.uri() == RequestUris[i]
          block: # Check null-termination for cstring compat
            let uri = req.uri()
            let puri = cast[ptr UncheckedArray[char]](uri[0].unsafeAddr)
            puri[uri.len] == '\0'
          req.version == RequestVersions[i]
          len(req) == RequestHeaders[i][1] - RequestHeaders[i][0] + 1
          req.contentLength() == RequestCLengths[i]
      else:
        check:
          req.success() == false
          req.failed() == true
          req.state == RequestResults[i]
          req.contentLength() == RequestCLengths[i]

      if len(req) > 0:
        for citem in req.headers():
          var found = false
          for ei in RequestHeaders[i][0]..RequestHeaders[i][1]:
            if cmpIgnoreCase(citem.name, RequestHeaderTexts[ei].k) == 0 and
               cmpIgnoreCase(citem.value, RequestHeaderTexts[ei].v) == 0:
              found = true
              break
          check found == true

        for ei in RequestHeaders[i][0]..RequestHeaders[i][1]:
          check (RequestHeaderTexts[ei].k in req) == true

        for ei in RequestHeaders[i][0]..RequestHeaders[i][1]:
          check (req[RequestHeaderTexts[ei].k] == RequestHeaderTexts[ei].v)

  test "HTTP Response Vectors":
    for i in 0..<len(ResponseVectors):
      var a = cast[seq[char]](ResponseVectors[i])
      var resp = parseResponse(a)
      if ResponseResults[i] == 0x9F:
        check:
          resp.success() == true
          resp.reason() == ResponseReasons[i]
          resp.version == ResponseVersions[i]
          resp.code == ResponseCodes[i]
          len(resp) == ResponseHeaders[i][1] - ResponseHeaders[i][0] + 1
          resp.contentLength() == ResponseCLengths[i]
      else:
        check:
          resp.success() == false
          resp.failed() == true
          resp.state == ResponseResults[i]
          resp.contentLength() == ResponseCLengths[i]

      if len(resp) > 0:
        for citem in resp.headers():
          var found = false
          for ei in ResponseHeaders[i][0]..ResponseHeaders[i][1]:
            if cmpIgnoreCase(citem.name, ResponseHeaderTexts[ei].k) == 0 and
               cmpIgnoreCase(citem.value, ResponseHeaderTexts[ei].v) == 0:
              found = true
              break
          check found == true

        for ei in ResponseHeaders[i][0]..ResponseHeaders[i][1]:
          check (ResponseHeaderTexts[ei].k in resp) == true

        for ei in ResponseHeaders[i][0]..ResponseHeaders[i][1]:
          check (resp[ResponseHeaderTexts[ei].k] == ResponseHeaderTexts[ei].v)

  test "HTTP request methods test":
    const MethodRequests = [
      ("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodGet),
      ("POST / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodPost),
      ("HEAD / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodHead),
      ("PUT / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodPut),
      ("DELETE / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodDelete),
      ("TRACE / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodTrace),
      ("OPTIONS / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodOptions),
      ("CONNECT / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodConnect),
      ("PATCH / HTTP/1.1\r\nHost: www.google.com\r\n\r\n", MethodPatch)
    ]

    for item in MethodRequests:
      var req = parseRequest(item[0], true)
      check:
        req.success()
        req.meth == item[1]

  test "HTTP methods conversion vectors":
    check:
      $MethodGet == "GET"
      $MethodPost == "POST"
      $MethodHead == "HEAD"
      $MethodPut == "PUT"
      $MethodDelete == "DELETE"
      $MethodTrace == "TRACE"
      $MethodOptions == "OPTIONS"
      $MethodConnect == "CONNECT"
      $MethodPatch == "PATCH"
      $MethodError == "ERROR"

  test "Validate header name/value":
    var chs = " "
    for a in 0..255:
      if chr(a) notin HEADERNAME:
        chs[0] = chr(a)
        check checkHeaderName(chs) == false
      else:
        chs[0] = chr(a)
        check checkHeaderName(chs) == true

    chs = " "
    for a in 0..255:
      if chr(a) notin {'\r', '\n'}:
        chs[0] = chr(a)
        check checkHeaderValue(chs) == true
      else:
        chs[0] = chr(a)
        check checkHeaderValue(chs) == false

  test "Parsing headers test":
    var headersStr = ""
    for item in ResponseHeaderTexts:
      let line = item.k & ": " & item.v & "\r\n"
      headersStr.add(line)
    headersStr.add("\r\n")
    var headersSeq = newSeq[byte](len(headersStr))
    copyMem(addr headersSeq[0], addr headersStr[0], len(headersSeq))
    let list = parseHeaders(headersSeq)
    check:
      list.success() == true
      len(list) == len(ResponseHeaderTexts)

  test "Content-Disposition test vectors":
    type TestOutput = (bool, string, seq[(string, string)])

    proc runDispTest(test: string): TestOutput =
      let cdisp = parseDisposition(test, true)
      var fields: seq[tuple[k: string, v: string]]
      if cdisp.success():
        for k, v in cdisp.fields():
          fields.add((k, v))
        (true, cdisp.dispositionType(), fields)
      else:
        (false, "", fields)

    check:
      runDispTest("") == (false, "", @[]).TestOutput
      runDispTest("a") == (true, "a", @[]).TestOutput
      runDispTest("aa") == (true, "aa", @[]).TestOutput
      runDispTest("form-data") == (true, "form-data", @[]).TestOutput
      runDispTest("form-data; name=token5; value=token6") ==
        (true, "form-data", @[("name", "token5"), ("value", "token6")])
      runDispTest("form-data; name=\"quoted1\"; filename=\"quoted2.txt\"") ==
        (true, "form-data", @[("name", "quoted1"), ("filename", "quoted2.txt")])
      runDispTest("form-data; filename=\"quoted.txt\";name=noquote") ==
        (true, "form-data", @[("filename", "quoted.txt"), ("name", "noquote")])
      runDispTest("form-data; filename=\"123\\\"\\\"\\\"456\"") ==
        (true, "form-data", @[("filename", "123\"\"\"456")])
      runDispTest("form-data; filename=123\"") == (false, "", @[]).TestOutput
      runDispTest("form-data; filename=123;") == (false, "", @[]).TestOutput
      runDispTest("form-data; filename=123") ==
        (true, "form-data", @[("filename", "123")])
      runDispTest("form-data; filename=\"\"") ==
        (true, "form-data", @[("filename", "")])
      runDispTest("form-data; filename=") ==
        (true, "form-data", @[("filename", "")])
      runDispTest("form-data; a=;b=;c=;d=\"\";e=") ==
        (true, "form-data", @[("a", ""), ("b", ""), ("c", ""), ("d", ""),
                              ("e", "")])
      runDispTest("form-data;a=\"''''\"") ==
        (true, "form-data", @[("a", "''''")])

  test "Accept header test vectors":
    # This is default accept header strings for different browsers
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Content_negotiation/List_of_default_Accept_values
    const SuccessVectors = [
      ("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        @[
          ("text/html", "", 1.0),
          ("application/xhtml+xml", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("image/webp", "", 1.0),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        @[
          ("text/html", "", 1.0),
          ("application/xhtml+xml", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        @[
          ("text/html", "", 1.0),
          ("application/xhtml+xml", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("image/webp", "", 1.0),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        @[
          ("text/html", "", 1.0),
          ("application/xhtml+xml", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        @[
          ("text/html", "", 1.0),
          ("application/xhtml+xml", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("image/webp", "", 1.0),
          ("image/apng", "", 1.0),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("image/jpeg, application/x-ms-application, image/gif, application/xaml+xml, image/pjpeg, application/x-ms-xbap, application/x-shockwave-flash, application/msword, */*",
        @[
          ("image/jpeg", "", 1.0),
          ("application/x-ms-application", "", 1.0),
          ("image/gif", "", 1.0),
          ("application/xaml+xml", "", 1.0),
          ("image/pjpeg", "", 1.0),
          ("application/x-ms-xbap", "", 1.0),
          ("application/x-shockwave-flash", "", 1.0),
          ("application/msword", "", 1.0),
          ("*/*", "", 1.0)
        ]
      ),
      ("text/html, application/xhtml+xml, image/jxr, */*",
        @[
          ("text/html", "", 1.0),
          ("application/xhtml+xml", "", 1.0),
          ("image/jxr", "", 1.0),
          ("*/*", "", 1.0)
        ]
      ),
      ("text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/webp, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1",
        @[
          ("text/html", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("application/xhtml+xml", "", 1.0),
          ("image/png", "", 1.0),
          ("image/webp", "", 1.0),
          ("image/jpeg", "", 1.0),
          ("image/gif", "", 1.0),
          ("image/x-xbitmap", "", 1.0),
          ("*/*", "q=0.1", 0.1)
        ]
      ),
      ("image/webp,*/*",
        @[
          ("image/webp", "", 1.0),
          ("*/*", "", 1.0)
        ]
      ),
      ("*/*",
        @[
          ("*/*", "", 1.0)
        ]
      ),
      ("image/png,image/*;q=0.8,*/*;q=0.5",
        @[
          ("image/png", "", 1.0),
          ("image/*", "q=0.8", 0.8),
          ("*/*", "q=0.5", 0.5)
        ]
      ),
      ("image/webp,image/png,image/svg+xml,image/*;q=0.8,video/*;q=0.8,*/*;q=0.5",
        @[
          ("image/webp", "", 1.0),
          ("image/png", "", 1.0),
          ("image/svg+xml", "", 1.0),
          ("image/*", "q=0.8", 0.8),
          ("video/*", "q=0.8", 0.8),
          ("*/*", "q=0.5", 0.5)
        ]
      ),
      ("image/png,image/svg+xml,image/*;q=0.8,video/*;q=0.8,*/*;q=0.5",
        @[
          ("image/png", "", 1.0),
          ("image/svg+xml", "", 1.0),
          ("image/*", "q=0.8", 0.8),
          ("video/*", "q=0.8", 0.8),
          ("*/*", "q=0.5", 0.5)
        ]
      ),
      ("image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        @[
          ("image/avif", "", 1.0),
          ("image/webp", "", 1.0),
          ("image/apng", "", 1.0),
          ("image/*", "", 1.0),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("image/png,image/svg+xml,image/*;q=0.8, */*;q=0.5",
        @[
          ("image/png", "", 1.0),
          ("image/svg+xml", "", 1.0),
          ("image/*", "q=0.8", 0.8),
          ("*/*", "q=0.5", 0.5)
        ]
      ),
      ("video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5",
        @[
          ("video/webm", "", 1.0),
          ("video/ogg", "", 1.0),
          ("video/*", "q=0.9", 0.9),
          ("application/ogg", "q=0.7", 0.7),
          ("audio/*", "q=0.6", 0.6),
          ("*/*", "q=0.5", 0.5)
        ]
      ),
      ("audio/webm,audio/ogg,audio/wav,audio/*;q=0.9,application/ogg;q=0.7,video/*;q=0.6,*/*;q=0.5",
        @[
          ("audio/webm", "", 1.0),
          ("audio/ogg", "", 1.0),
          ("audio/wav", "", 1.0),
          ("audio/*", "q=0.9", 0.9),
          ("application/ogg", "q=0.7", 0.7),
          ("video/*", "q=0.6", 0.6),
          ("*/*", "q=0.5", 0.5)
        ]
      ),
      ("application/javascript, */*;q=0.8",
        @[
          ("application/javascript", "", 1.0),
          ("*/*", "q=0.8", 0.8)
        ]
      ),
      ("text/css,*/*;q=0.1",
        @[
          ("text/css", "", 1.0),
          ("*/*", "q=0.1", 0.1)
        ]
      ),
      ("text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/webp, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1",
        @[
          ("text/html", "", 1.0),
          ("application/xml", "q=0.9", 0.9),
          ("application/xhtml+xml", "", 1.0),
          ("image/png", "", 1.0),
          ("image/webp", "", 1.0),
          ("image/jpeg", "", 1.0),
          ("image/gif", "", 1.0),
          ("image/x-xbitmap", "", 1.0),
          ("*/*", "q=0.1", 0.1)
        ]
      ),
      ("",
        @[
          ("*/*", "", 1.0)
        ]
      )
    ]

    for vector in SuccessVectors:
      let info = getAcceptInfo(vector[0])
      check info.isOk() == true
      var items = info.get().data
      check len(items) == len(vector[1])
      var expects = vector[1]
      for item in items:
        let tocheck = ($item.mediaType, item.parameters(), item.qvalue)
        let index = expects.find(tocheck)
        check index >= 0
        expects.del(index)

  test "Q-value parser tests":
    const FailureVectors = [
      "1.0000", "0.0000", "2", "a", ".", "1#", "0#", "1.1", "1.2", "1.a",
      "0.a", "1.01", "1.11", "1.10", "1.001", "1.010", "1.011", "1.100",
      "1.101", "1.110", "1.111", "1.009", "0.00a", "0.0a0", "0.a00",
      "1,", "1,0", "1,00", "1,000", "0,", "0,0", "0,00", "0,000", "0 ",
      "0 00", "0 000", "1 000"
    ]
    check:
      getQvalue("1").tryGet() == 1.0
      getQvalue("0").tryGet() == 0.0
      getQvalue("1.").tryGet() == 1.0
      getQvalue("0.").tryGet() == 0.0
      getQvalue("1.0").tryGet() == 1.0
      getQvalue("0.0").tryGet() == 0.0
      getQvalue("1.00").tryGet() == 1.0
      getQvalue("0.00").tryGet() == 0.0
      getQvalue("1.000").tryGet() == 1.0
      getQvalue("0.000").tryGet() == 0.0

    for i in 0 ..< 1000:
      let qres = getQvalue("0." & $i)
      check qres.isOk() == true

    for i in 1 ..< 1000:
      let qres = getQvalue("1." & $i)
      check qres.isErr() == true

    for item in FailureVectors:
      check getQvalue(item).isErr() == true

  test "Media-type comparison tests":
    check:
      cmp(MediaType.init("*/*"), MediaType.init("*/*")) == 0
      cmp(MediaType.init("application/json"), MediaType.init("*/*")) == 0
      cmp(MediaType.init("*/*"), MediaType.init("application/json")) == 0
      cmp(MediaType.init("*/json"), MediaType.init("*/*")) == 0
      cmp(MediaType.init("*/*"), MediaType.init("*/json")) == 0
      cmp(MediaType.init("application/*"), MediaType.init("*/*")) == 0
      cmp(MediaType.init("*/*"), MediaType.init("application/*")) == 0
      cmp(MediaType.init("application/*"), MediaType.init("*/json")) == 0
      cmp(MediaType.init("*/json"), MediaType.init("application/*")) == 0
      cmp(MediaType.init("application/json"),
          MediaType.init("application/cbor")) != 0
      cmp(MediaType.init("*/json"),
          MediaType.init("application/cbor")) != 0
      cmp(MediaType.init("application/cbor"),
          MediaType.init("*/json")) != 0

  test "Content-type selection tests":
    const
      jsonMediaType = MediaType.init("application/json")
      sszMediaType = MediaType.init("application/octet-stream")
      plainTextMediaType = MediaType.init("text/plain")
      imageMediaType = MediaType.init("image/jpg")

      singleHeader = @[
        (
          "application/json",
          @[
            "application/json"
          ]
        )
      ]

      acceptHeaders = [
        ("application/json, application/octet-stream",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json"
           ]
        ),
        ("application/octet-stream, application/json",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json"
           ]
        ),
        ("application/json;q=0.9, application/octet-stream",
         @[
            "application/json",
            "application/octet-stream",
            "application/octet-stream",
            "application/octet-stream",
            "application/octet-stream",
            "application/octet-stream"
           ]
        ),
        ("application/json, application/octet-stream;q=0.9",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json",
            "application/json",
            "application/json"
           ]
        ),
        ("application/json;q=0.9, application/octet-stream;q=0.8",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json",
            "application/json",
            "application/json"
           ]
        ),
        ("text/plain, application/octet-stream, application/json",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json"
           ]
        ),
        ("text/plain, application/json;q=0.8, application/octet-stream;q=0.8",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "text/plain",
            "text/plain"
           ]
        ),
        ("text/plain, application/json;q=0.8, application/octet-stream;q=0.5",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json",
            "text/plain",
            "text/plain"
           ]
        ),
        ("text/plain;q=0.8, application/json, application/octet-stream;q=0.8",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json",
            "application/json",
            "application/json"
           ]
        ),
        ("text/*, application/json, application/octet-stream",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json"
           ]
        ),
        ("text/*, application/json;q=0.8, application/octet-stream;q=0.5",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json",
            "text/plain",
            "text/plain"
           ]
        ),
        ("image/jpg, text/plain, application/octet-stream, application/json",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "image/jpg"
           ]
        ),
        ("image/jpg;q=1, text/plain;q=0.2, application/octet-stream;q=0.2, application/json;q=0.2",
         @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "image/jpg"
           ]
        ),
        ("*/*",
         @[
             "application/json",
             "application/octet-stream",
             "application/json",
             "application/octet-stream",
             "application/json",
             "image/jpg"
           ]
        ),
        (
          "application/*",
          @[
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/octet-stream",
            "application/json",
            "application/json"
          ]
        )
      ]

    for vector in singleHeader:
      let res0 = selectContentType(getAcceptInfo(vector[0]).get().data, jsonMediaType)
      let res1 = selectContentType(getAcceptInfo(vector[0]).get().data, sszMediaType)
      let res2 = selectContentType(getAcceptInfo(vector[0]).get().data, jsonMediaType,
                                                                        sszMediaType)
      let res3 = selectContentType(getAcceptInfo(vector[0]).get().data, sszMediaType,
                                                                        jsonMediaType)
      let res4 = selectContentType(getAcceptInfo(vector[0]).get().data, jsonMediaType,
                                                                        sszMediaType,
                                                                        plainTextMediaType)
      let res5 = selectContentType(getAcceptInfo(vector[0]).get().data, imageMediaType,
                                                                        jsonMediaType,
                                                                        sszMediaType,
                                                                        plainTextMediaType)
      check:
        res0.isOk() == true
        res1.isErr() == true
        res2.isOk() == true
        res3.isOk() == true
        res4.isOk() == true
        res5.isOk() == true
        res0.get() == MediaType.init(vector[1][0])
        res2.get() == MediaType.init(vector[1][0])
        res3.get() == MediaType.init(vector[1][0])
        res4.get() == MediaType.init(vector[1][0])
        res5.get() == MediaType.init(vector[1][0])

    for vector in acceptHeaders:
      let res0 = selectContentType(getAcceptInfo(vector[0]).get().data, jsonMediaType)
      let res1 = selectContentType(getAcceptInfo(vector[0]).get().data, sszMediaType)
      let res2 = selectContentType(getAcceptInfo(vector[0]).get().data, jsonMediaType,
                                                                        sszMediaType)
      let res3 = selectContentType(getAcceptInfo(vector[0]).get().data, sszMediaType,
                                                                        jsonMediaType)
      let res4 = selectContentType(getAcceptInfo(vector[0]).get().data, jsonMediaType,
                                                                        sszMediaType,
                                                                        plainTextMediaType)
      let res5 = selectContentType(getAcceptInfo(vector[0]).get().data, imageMediaType,
                                                                        jsonMediaType,
                                                                        sszMediaType,
                                                                        plainTextMediaType)
      check:
        res0.isOk() == true
        res1.isOk() == true
        res2.isOk() == true
        res3.isOk() == true
        res4.isOk() == true
        res5.isOk() == true
        res0.get() == MediaType.init(vector[1][0])
        res1.get() == MediaType.init(vector[1][1])
        res2.get() == MediaType.init(vector[1][2])
        res3.get() == MediaType.init(vector[1][3])
        res4.get() == MediaType.init(vector[1][4])
        res5.get() == MediaType.init(vector[1][5])

  test "Content-Type header parser mime-types vectors test":
    let filename = "tests/mimetypes.txt"
    for line in filename.lines():
      if len(line) != 0:
        check:
          getContentType(line).isOk()
          getContentType(line & "; charset=utf-8").isOk()
          getContentType(line & "; charset=\"utf-8\"").isOk()

  test "Content-Type header parser test vectors":

    const
      Token = "!#$%&'*+-.^_`|~0123456789abcdefghijklmnopqrstuvwxyz" &
                                       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      QdText =
        "\t !#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ" &
        "[]^_`abcdefghijklmnopqrstuvwxyz{|}~" &
        "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F" &
        "\x90\x91\x92\x93\x94\x95\x96\x97\x99\x99\x9A\x9B\x9C\x9D\x9E\x9F" &
        "\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xAA\xA9\xAA\xAB\xAC\xAD\xAE\xAF" &
        "\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xBB\xB9\xBA\xBB\xBC\xBD\xBE\xBF" &
        "\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xCC\xC9\xCA\xCB\xCC\xCD\xCE\xCF" &
        "\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xDD\xD9\xDA\xDB\xDC\xDD\xDE\xDF" &
        "\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xEE\xE9\xEA\xEB\xEC\xEE\xEE\xEF" &
        "\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xFF\xF9\xFA\xFB\xFC\xFF\xFE\xFF"

      FailureVectors = [
        "",
        "\x7F",
        "\x80",
        "\xFF",
        " ",
        "\t",
        "text",
        "html",
        "text/",
        "text\\",
        " text/html",
        "\xFFtext/html",
        "\x80text/html",
        "\x7Ftext/html",
        "tex\x7Ft/html",
        "text/\xFFhtml",
        "text/\x80html",
        "text/\x7Fhtml",
        "text/html;",
        "text/html; ",
        "text/html;a",
        "text/html;\xFF",
        "text/html;\x80",
        "text/html;\x7F",
        "text/html;a=;",
        "text/html;a=b;b=c;c=d;",
        "text/html;a=b;b=c;c=d; ",
        "text/html;a=\"",
        "text/html;a=\"\"\"",
        "text/html;a=\x7F",
        "text/html;a=\x80",
        "text/html;a=\xFF",
        "text/html;a=\x00",
        "text/html;a=\x1F",
        "text/html;a=\"\x00\"",
        "text/html;a=\"\x1F\"",
        "text/html;a= "
      ]

      SuccessVectors = [
        ("text/html;a=", ("text/html",
          @[("a", "")])),
        ("text/html", ("text/html",
          @[])),
        ("text/html;a=\"\"", ("text/html",
          @[("a", "")])),
        ("text/html;a=\"\\\\\"", ("text/html",
          @[("a", "\\")])),
        ("text/html;a=\"\\\"\"", ("text/html",
          @[("a", "\"")])),
        ("text/html;a=\"\\aa\"", ("text/html",
          @[("a", "aa")])),
        ("text/html;a=\"\x80\xFF\"", ("text/html",
          @[("a", "\x80\xFF")])),
        ("text/html;a=\"\t\"", ("text/html",
          @[("a", "\t")])),
        ("text/html;a=\" \"", ("text/html",
          @[("a", " ")])),
        ("text/html;a=b", ("text/html",
          @[("a", "b")])),
        ("text/html;a=\"b\"", ("text/html",
          @[("a", "b")])),
        ("text/html;a=b;b=c", ("text/html",
          @[("a", "b"), ("b", "c")])),
        ("text/html;a=b;b=c;c=d", ("text/html",
          @[("a", "b"), ("b", "c"), ("c", "d")])),
        ("text/html;a=;b=;c=", ("text/html",
          @[("a", ""), ("b", ""), ("c", "")])),
        ("text/html;a=;b=c;c=d", ("text/html",
          @[("a", ""), ("b", "c"), ("c", "d")])),
        ("text/html;a=b;b=;c=d", ("text/html",
          @[("a", "b"), ("b", ""), ("c", "d")])),
        ("text/html;a=b;b=c;c=", ("text/html",
          @[("a", "b"), ("b", "c"), ("c", "")])),
        ("text/html;a=;b=\"\";c=", ("text/html",
          @[("a", ""), ("b", ""), ("c", "")])),
        ("text/html;a=;b=\"\";c=\"\"", ("text/html",
          @[("a", ""), ("b", ""), ("c", "")]))
      ]
    for item in FailureVectors:
      check getContentType(item).isErr()

    for item in SuccessVectors:
      let res = getContentType(item[0])
      check res.isOk()
      let content = res.get()
      check:
        content.mediaType.media & "/" & content.mediaType.subtype == item[1][0]
      let params = content.params
      check:
        len(params) == len(item[1][1])
      for index, param in params.pairs():
        check:
          param[0] == item[1][1][index][0]
          param[1] == item[1][1][index][1]

    block:
      # Token/Token; Token=Token; Token="QdText"
      let contentType = Token & "/" & Token & "; " &
                        Token & "=" & Token & "; " &
                        Token & "=\"" & QdText & "\""
      let res = getContentType(contentType)
      check res.isOk()
      let data = res.get()
      check:
        data.mediaType.media == Token
        data.mediaType.subtype == Token
        data.params[0] == (name: Token, value: Token)
        data.params[1] == (name: Token, value: QdText)

  test "isValid(MediaType) test":
    let filename = "tests/mimetypes.txt"
    for line in filename.lines():
      if len(line) != 0:
        check isValid(MediaType.init(line)) == true
    check:
      isValid(MediaType.init("*/*")) == true
      isValid(MediaType.init("application/*")) == true

  test "isWildCard(MediaType) test":
    let filename = "tests/mimetypes.txt"
    for line in filename.lines():
      if len(line) != 0:
        check isWildCard(MediaType.init(line)) == false
    check:
      isWildCard(MediaType.init("*/*")) == true
      isWildCard(MediaType.init("text/*")) == true
      isWildCard(MediaType.init("image/*")) == true

  test "(ContentTypeData, MediaType) comparison":
    let filename = "tests/mimetypes.txt"
    for line in filename.lines():
      if len(line) != 0:
        let
          contentType1 = getContentType(line & "; charset=utf-8").tryGet()
          contentType2 = getContentType(line & "; charset=ISO-8859-1").tryGet()
          mediaType = MediaType.init(line)

        check:
          contentType1 == mediaType
          contentType2 == mediaType
          contentType1 == MediaType.init("*/*")

  test "(ContentTypeData, ContentTypeData) comparison":
    let filename = "tests/mimetypes.txt"
    for line in filename.lines():
      if len(line) != 0:
        let
          contentType1 = getContentType(line).tryGet()
          contentType2 = getContentType(line & "; charset=\"utf-8\"").tryGet()
          contentType3 = getContentType(line & "; charset=utf-8").tryGet()
          contentType4 = getContentType(line & "; ChArSeT=utf-8").tryGet()
          contentType5 = getContentType(line & "; ChArSeT=UTF-8").tryGet()
          contentType6 = getContentType(line & "; ChArSeT=ISO-8859-1").tryGet()
          contentType7 = getContentType(line & "; ChArSeT=iso-8859-1").tryGet()

        check:
          contentType1 == contentType1
          contentType1 != contentType2
          contentType1 != contentType3
          contentType1 != contentType4
          contentType1 != contentType5
          contentType1 != contentType6
          contentType1 != contentType7

          contentType2 == contentType2
          contentType2 == contentType3
          contentType2 == contentType4
          contentType2 == contentType5
          contentType2 != contentType6
          contentType2 != contentType7

          contentType3 == contentType3
          contentType3 == contentType4
          contentType3 == contentType5
          contentType3 != contentType6
          contentType3 != contentType7

          contentType4 == contentType4
          contentType4 == contentType5
          contentType4 != contentType6
          contentType4 != contentType7

          contentType5 == contentType5
          contentType5 != contentType6
          contentType5 != contentType7

          contentType6 == contentType6
          contentType6 == contentType7

          contentType7 == contentType7

  test "ContenTypeData to string test":
    let filename = "tests/mimetypes.txt"
    for line in filename.lines():
      if len(line) != 0:
        let header = line & "; charset=\"utf-8\"; boundary=\"boundary\""
        let contentType = getContentType(
          line & "; charset=utf-8; boundary=boundary").tryGet()
        check:
          $contentType == header
    check:
      $ContentTypeData(status: HttpStatus.Failure) == "<incomplete>"
