import unittest, strutils
import ../httputils

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
    proc runDispTest(test: string): auto =
      let cdisp = parseDisposition(test, true)
      var fields: seq[tuple[k: string, v: string]]
      if cdisp.success():

        for k, v in cdisp.fields():
          fields.add((k, v))
        (true, cdisp.dispositionType(), fields)
      else:
        (false, "", fields)

    check:
      runDispTest("") == (false, "", @[])
      runDispTest("a") == (true, "a", @[])
      runDispTest("aa") == (true, "aa", @[])
      runDispTest("form-data") == (true, "form-data", @[])
      runDispTest("form-data; name=token5; value=token6") ==
        (true, "form-data", @[("name", "token5"), ("value", "token6")])
      runDispTest("form-data; name=\"quoted1\"; filename=\"quoted2.txt\"") ==
        (true, "form-data", @[("name", "quoted1"), ("filename", "quoted2.txt")])
      runDispTest("form-data; filename=\"quoted.txt\";name=noquote") ==
        (true, "form-data", @[("filename", "quoted.txt"), ("name", "noquote")])
      runDispTest("form-data; filename=\"123\\\"\\\"\\\"456\"") ==
        (true, "form-data", @[("filename", "123\"\"\"456")])
      runDispTest("form-data; filename=123\"") == (false, "", @[])
      runDispTest("form-data; filename=123;") == (false, "", @[])
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
