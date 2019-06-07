#
#                   HTTP Utilities
#                 (c) Copyright 2018
#         Status Research & Development GmbH
#
#              Licensed under either of
#  Apache License, version 2.0, (LICENSE-APACHEv2)
#              MIT license (LICENSE-MIT)

import times, strutils

const
  ALPHA* = {'a'..'z', 'A'..'Z'}
  NUM* = {'0'..'9'}
  TOKEND* = {'!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '^', '_', '`',
            '|', '~'}
  # HTTP token delimeters
  URITOKEND* = {'-', '.', '_', '~', ':', '/', '?', '#', '[', ']', '@', '!',
               '$', '&', '\'', '(', ')', '*', '+', ',', ';', '=', '%'}
  # URI token delimeters
  SPACE* = {' ', '\t'}
  COLON* = {':'}
  SLASH* = {'/'}
  DOT* = {'.'}
  CR* = char(0x0D)
  LF* = char(0x0A)
  ALPHANUM = ALPHA + NUM
  TOKENURI = TOKEND * URITOKEND - DOT
  TOKENONLY = TOKEND - URITOKEND - DOT
  URIONLY = URITOKEND - TOKEND - COLON - SLASH - DOT
  HEADERNAME* = ALPHANUM + TOKENURI + TOKENONLY + DOT

  # Legend:
  # [0x81, 0x8D] - markers
  # 0x81 - start HTTP request method
  # 0x82 - end of HTTP request method
  # 0x83 - start of HTTP request URI
  # 0x84 - end of HTTP request URI
  # 0x85 - start of HTTP version
  # 0x86 - end of HTTP version
  # 0x87 - LF
  # 0x88 - start of header name
  # 0x89 - end of header name
  # 0x8A - start of header value
  # 0x8B - end of header value
  # 0x8C - last header LF
  # 0x8D - header's finish
  # [0xC0, 0xCF] - errors

  # *     ALPHA NUM   TO^UR TOON  URON  CR    LF    COLON SLASH DOT   SPACE PAD   PAD   PAD   PAD
  requestSM = [
    0xC0, 0x81, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xCF, 0xCF, 0xCF, 0xCF, # s00: first method char
    0xC1, 0x01, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0x82, 0xCF, 0xCF, 0xCF, 0xCF, # s01: method
    0xC2, 0x83, 0x83, 0x83, 0xC2, 0x83, 0xC2, 0xC2, 0x83, 0x83, 0x83, 0xC2, 0xCF, 0xCF, 0xCF, 0xCF, # s02: first uri char
    0xC2, 0x03, 0x03, 0x03, 0xC2, 0x03, 0xC2, 0xC2, 0x03, 0x03, 0x03, 0x84, 0xCF, 0xCF, 0xCF, 0xCF, # s03: uri
    0xC3, 0x85, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xCF, 0xCF, 0xCF, 0xCF, # s04: first version char
    0xC3, 0x05, 0x05, 0xC3, 0xC3, 0xC3, 0x86, 0xC3, 0xC3, 0x05, 0x05, 0xC3, 0xCF, 0xCF, 0xCF, 0xCF, # s05: version
    0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0x87, 0xC4, 0xC4, 0xC4, 0xC4, 0xCF, 0xCF, 0xCF, 0xCF, # s06: LF
    0xC5, 0x88, 0x88, 0x88, 0x88, 0xC5, 0x8D, 0xC5, 0xC5, 0xC5, 0x88, 0xC5, 0xCF, 0xCF, 0xCF, 0xCF, # s07: first token char
    0xC5, 0x08, 0x08, 0x08, 0x08, 0xC5, 0xC5, 0xC5, 0x89, 0xC5, 0x08, 0xC5, 0xCF, 0xCF, 0xCF, 0xCF, # s08: header name
    0x8B, 0x8B, 0x8B, 0x8B, 0x8B, 0x8B, 0x8C, 0xC6, 0x8B, 0x8B, 0x8B, 0x8A, 0xCF, 0xCF, 0xCF, 0xCF, # s09: first header char
    0x8B, 0x8B, 0x8B, 0x8B, 0x8B, 0xC6, 0x8C, 0xC6, 0x8B, 0x8B, 0x8B, 0x0A, 0xCF, 0xCF, 0xCF, 0xCF, # s0a: 1st space
    0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x8C, 0xC7, 0x0B, 0x0B, 0x0B, 0x0B, 0xCF, 0xCF, 0xCF, 0xCF, # s0b: header value
    0xC7, 0xC7, 0xC7, 0xC7, 0xC7, 0xC7, 0xC7, 0x87, 0xC7, 0xC7, 0xC7, 0xC7, 0xCF, 0xCF, 0xCF, 0xCF, # s0c: header LF
    0xC8, 0xC8, 0xC8, 0xC8, 0xC8, 0xC8, 0xC8, 0x8E, 0xC8, 0xC8, 0xC8, 0xC8, 0xCF, 0xCF, 0xCF, 0xCF  # s0d: last LF
  ]

  # Legend:
  # [0x81, 0x8D] - markers
  # 0x81 - start HTTP version
  # 0x82 - end of HTTP version
  # 0x83 - start of HTTP response code
  # 0x84 - end of HTTP response code
  # 0x85 - start of HTTP reason string
  # 0x86 - end of HTTP reason string
  # 0x87 - LF
  # 0x88 - start of header name
  # 0x89 - end of header name
  # 0x8A - start of header value
  # 0x8B - end of header value
  # 0x8C - last header LF
  # 0x8D - header's finish
  # [0xC0, 0xCF] - errors

  # *     ALPHA NUM   TO^UR TOON  URON  CR    LF    COLON SLASH DOT   SPACE PAD   PAD   PAD   PAD
  responseSM = [
    0xC0, 0x81, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xCF, 0xCF, 0xCF, 0xCF, # s00: first version char
    0xC1, 0x01, 0x01, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0x01, 0x01, 0x82, 0xCF, 0xCF, 0xCF, 0xCF, # s01: version
    0xC2, 0xC2, 0x83, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xCF, 0xCF, 0xCF, 0xCF, # s02: first code char
    0xC2, 0xC2, 0x03, 0xC2, 0xC2, 0xC2, 0x84, 0xC2, 0xC2, 0xC2, 0xC2, 0x85, 0xCF, 0xCF, 0xCF, 0xCF, # s03: code
    0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0x88, 0xC2, 0xC2, 0xC2, 0xC2, 0xCF, 0xCF, 0xCF, 0xCF, # s04: no reason LF
    0xC3, 0x86, 0x86, 0x86, 0x86, 0x86, 0xC3, 0xC3, 0x86, 0x86, 0x86, 0x86, 0xCF, 0xCF, 0xCF, 0xCF, # s05: first reason char
    0xC3, 0x06, 0x06, 0x06, 0x06, 0x06, 0x87, 0xC3, 0x06, 0x06, 0x06, 0x06, 0xCF, 0xCF, 0xCF, 0xCF, # s06: reason
    0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0x88, 0xC3, 0xC3, 0xC3, 0xC3, 0xCF, 0xCF, 0xCF, 0xCF, # s07: LF
    0xC3, 0x8A, 0x8A, 0x8A, 0x8A, 0xC3, 0x8F, 0xC3, 0xC3, 0xC3, 0x8A, 0xC4, 0xCF, 0xCF, 0xCF, 0xCF, # s08: no headers CR
    0xC4, 0x8A, 0x8A, 0x8A, 0x8A, 0xC4, 0x8F, 0xC4, 0xC4, 0xC4, 0x8A, 0xC4, 0xCF, 0xCF, 0xCF, 0xCF, # s09: first token char
    0xC4, 0x0A, 0x0A, 0x0A, 0x0A, 0xC4, 0xC4, 0xC4, 0x8B, 0xC4, 0x0A, 0xC4, 0xCF, 0xCF, 0xCF, 0xCF, # s0a: header name
    0x8D, 0x8D, 0x8D, 0x8D, 0x8D, 0x8D, 0x8E, 0xC5, 0x8D, 0x8D, 0x8D, 0x8C, 0xCF, 0xCF, 0xCF, 0xCF, # s0b: first header char
    0x8D, 0x8D, 0x8D, 0x8D, 0x8D, 0xC5, 0x8E, 0xC5, 0x8D, 0x8D, 0x8D, 0x0C, 0xCF, 0xCF, 0xCF, 0xCF, # s0c: 1st space
    0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x8E, 0xC5, 0x0D, 0x0D, 0x0D, 0x0D, 0xCF, 0xCF, 0xCF, 0xCF, # s0d: header value
    0xC7, 0xC7, 0xC7, 0xC7, 0xC7, 0xC7, 0xC7, 0x89, 0xC7, 0xC7, 0xC7, 0xC7, 0xCF, 0xCF, 0xCF, 0xCF, # s0e: header LF
    0xC8, 0xC8, 0xC8, 0xC8, 0xC8, 0xC8, 0xC8, 0x9F, 0xC8, 0xC8, 0xC8, 0xC8, 0xCF, 0xCF, 0xCF, 0xCF, # s0f: last LF
  ]

type
  HttpCode* = enum
    ## HTTP error codes
    Http100 = "100 Continue",
    Http101 = "101 Switching Protocols",
    Http200 = "200 OK",
    Http201 = "201 Created",
    Http202 = "202 Accepted",
    Http203 = "203 Non-Authoritative Information",
    Http204 = "204 No Content",
    Http205 = "205 Reset Content",
    Http206 = "206 Partial Content",
    Http300 = "300 Multiple Choices",
    Http301 = "301 Moved Permanently",
    Http302 = "302 Found",
    Http303 = "303 See Other",
    Http304 = "304 Not Modified",
    Http305 = "305 Use Proxy",
    Http307 = "307 Temporary Redirect",
    Http400 = "400 Bad Request",
    Http401 = "401 Unauthorized",
    Http403 = "403 Forbidden",
    Http404 = "404 Not Found",
    Http405 = "405 Method Not Allowed",
    Http406 = "406 Not Acceptable",
    Http407 = "407 Proxy Authentication Required",
    Http408 = "408 Request Timeout",
    Http409 = "409 Conflict",
    Http410 = "410 Gone",
    Http411 = "411 Length Required",
    Http412 = "412 Precondition Failed",
    Http413 = "413 Request Entity Too Large",
    Http414 = "414 Request-URI Too Long",
    Http415 = "415 Unsupported Media Type",
    Http416 = "416 Requested Range Not Satisfiable",
    Http417 = "417 Expectation Failed",
    Http418 = "418 I'm a teapot",
    Http421 = "421 Misdirected Request",
    Http422 = "422 Unprocessable Entity",
    Http426 = "426 Upgrade Required",
    Http428 = "428 Precondition Required",
    Http429 = "429 Too Many Requests",
    Http431 = "431 Request Header Fields Too Large",
    Http451 = "451 Unavailable For Legal Reasons",
    Http500 = "500 Internal Server Error",
    Http501 = "501 Not Implemented",
    Http502 = "502 Bad Gateway",
    Http503 = "503 Service Unavailable",
    Http504 = "504 Gateway Timeout",
    Http505 = "505 HTTP Version Not Supported"

  HttpVersion* = enum
    ## HTTP version
    HttpVersion09
    HttpVersion11,
    HttpVersion10,
    HttpVersion20,
    HttpVersionError

  HttpMethod* = enum
    ## HTTP methods
    MethodGet,
    MethodPost,
    MethodHead,
    MethodPut,
    MethodDelete,
    MethodTrace,
    MethodOptions,
    MethodConnect,
    MethodPatch,
    MethodError

  HttpStatus* = enum
    ## HTTP parser status type
    Success, Failure

  HttpHeaderPart* = object
    ## HTTP offset representation object
    s*: int                  ## Start offset
    e*: int                  ## End offset

  HttpHeader* = object
    ## HTTP header representation object
    name*: HttpHeaderPart    ## Header name
    value*: HttpHeaderPart   ## Header value

  HttpRequestHeader* = object
    ## HTTP request header
    data: seq[byte]          ## Data blob
    meth*: HttpMethod        ## HTTP request method
    version*: HttpVersion    ## HTTP version
    status*: HttpStatus      ## HTTP headers processing status
    url: HttpHeaderPart
    state*: int
    hdrs: seq[HttpHeader]
    length*: int             ## HTTP headers length

  HttpResponseHeader* = object
    ## HTTP response header
    data: seq[byte]           ## Data blob
    version*: HttpVersion     ## HTTP version
    code*: int                ## HTTP result code
    status*: HttpStatus       ## HTTP headers processing status
    rsn: HttpHeaderPart
    state*: int
    hdrs: seq[HttpHeader]
    length*: int              ## HTTP headers length

  HttpReqRespHeader* = HttpRequestHeader | HttpResponseHeader

template processHeaders(sm: untyped, state: var int, ch: char): int =
  var res = true
  var code = 0
  case ch
  of ALPHA:
    code = 1
  of NUM:
    code = 2
  of TOKENURI:
    code = 3
  of TOKENONLY:
    code = 4
  of URIONLY:
    code = 5
  of CR:
    code = 6
  of LF:
    code = 7
  of COLON:
    code = 8
  of SLASH:
    code = 9
  of DOT:
    code = 10
  of SPACE:
    code = 11
  else:
    code = 0
  var newstate = sm[(state shl 4) + code]
  state = newstate and 0x0F
  newstate

proc processMethod(data: seq[char], s, e: int): HttpMethod =
  result = HttpMethod.MethodError
  let length = e - s + 1
  case char(data[s])
  of 'G':
    if length == 3:
      if data[s + 1] == 'E' and data[s + 2] == 'T':
        result = MethodGet
  of 'P':
    if length == 3:
      if data[s + 1] == 'U' and data[s + 2] == 'T':
        result = MethodPut
    elif length == 4:
      if data[s + 1] == 'O' and data[s + 2] == 'S' and data[s + 3] == 'T':
        result = MethodPost
    elif length == 5:
      if data[s + 1] == 'A' and data[s + 2] == 'T' and data[s + 3] == 'C' and
         data[s + 4] == 'H':
        result = MethodPatch
  of 'D':
    if length == 6:
      if data[s + 1] == 'E' and data[s + 2] == 'L' and data[s + 3] == 'E' and
         data[s + 4] == 'T' and data[s + 5] == 'E':
        result = MethodDelete
  of 'T':
    if length == 5:
      if data[s + 1] == 'R' and data[s + 2] == 'A' and data[s + 3] == 'C' and
         data[s + 4] == 'E':
       result = MethodTrace
  of 'O':
    if length == 7:
      if data[s + 1] == 'P' and data[s + 2] == 'T' and data[s + 3] == 'I' and
         data[s + 4] == 'O' and data[s + 5] == 'N' and data[s + 6] == 'S':
        result = MethodOptions
  of 'C':
    if length == 7:
      if data[s + 1] == 'O' and data[s + 2] == 'N' and data[s + 3] == 'N' and
         data[s + 4] == 'E' and data[s + 5] == 'C' and data[s + 6] == 'T':
        result = MethodConnect
  else:
    discard

proc processVersion(data: seq[char], s, e: int): HttpVersion =
  result = HttpVersionError
  let length = e - s + 1
  if length == 8:
    if data[s] == 'H' and data[s + 1] == 'T' and data[s + 2] == 'T' and
       data[s + 3] == 'P' and data[s + 4] == '/':
      if data[s + 5] == '1' and data[s + 6] == '.':
        if data[s + 7] == '0':
          result = HttpVersion10
        elif data[s + 7] == '1':
          result = HttpVersion11
      elif data[s + 5] == '0' and data[s + 6] == '.':
        if data[s + 7] == '9':
          result = HttpVersion09
      elif data[s + 5] == '2' and data[s + 6] == '.':
        if data[s + 7] == '0':
          result = HttpVersion20

proc processCode(data: seq[char], s, e: int): int =
  result = -1
  let length = e - s + 1
  if length == 3:
    result = (ord(data[s]) - ord('0')) * 100 +
             (ord(data[s + 1]) - ord('0')) * 10 +
             ord(data[s + 2]) - ord('0')

proc parseRequest*[T: char|byte](data: seq[T]): HttpRequestHeader =
  ## Parse sequence of characters or bytes as HTTP request header.
  ##
  ## Note: to prevent unnecessary allocations source array ``data`` will be
  ## be shallow copied to result and all parsed fields will have references to
  ## this buffer. If you plan to change contents of ``data`` while parsing
  ## request and/or processing headers, please make a real copy of ``data`` and
  ## pass copy to ``parseRequest(data)``.
  ##
  ## Returns `HttpRequestHeader` instance.
  var
    index = 0
    state = 0
    start = -1
    finish = 0
    hdr: HttpHeader

  result.status = HttpStatus.Failure
  result.version = HttpVersionError
  result.meth = MethodError
  result.hdrs = newSeq[HttpHeader]()

  if len(data) == 0:
    return

  # Preserve ``data`` sequence in our object.
  shallowCopy(result.data, cast[seq[byte]](data))

  while index < len(data):
    let ps = requestSM.processHeaders(state, char(data[index]))
    result.state = ps
    case ps
    of 0x81:
      start = index
    of 0x82:
      if start == -1:
        break
      finish = index - 1
      when T is byte:
        let m = processMethod(cast[seq[char]](data), start, finish)
      else:
        let m = processMethod(data, start, finish)
      if m == HttpMethod.MethodError:
        break
      result.meth = m
      start = -1
    of 0x83:
      start = index
    of 0x84:
      if start == -1:
        break
      finish = index - 1
      result.url = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x85:
      start = index
    of 0x86:
      if start == -1:
        break
      finish = index - 1
      when T is byte:
        let m = processVersion(cast[seq[char]](data), start, finish)
      else:
        let m = processVersion(data, start, finish)
      if m == HttpVersion.HttpVersionError:
        break
      result.version = m
      start = -1
    of 0x87, 0x8A, 0x8D:
      discard
    of 0x88:
      start = index
    of 0x89:
      if start == -1:
        break
      finish = index - 1
      hdr.name = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x8B:
      start = index
    of 0x8C:
      if start == -1:
        # empty header
        hdr.value = HttpHeaderPart(s: -1, e: -1)
      else:
        finish = index - 1
        hdr.value = HttpHeaderPart(s: start, e: finish)
      result.hdrs.add(hdr)
      start = -1
    of 0x8E:
      result.length = index + 1
      result.status = HttpStatus.Success
      break
    of 0xC0..0xCF:
      # error
      break
    of 0x00..0x0F:
      # data processing
      discard
    else:
      # must not be happened
      break
    inc(index)

proc parseResponse*[T: char|byte](data: seq[T]): HttpResponseHeader =
  ## Parse sequence of characters or bytes as HTTP response header.
  ## Returns `HttpResponseHeader` instance.
  var
    index = 0
    state = 0
    start = -1
    finish = 0
    hdr: HttpHeader

  result.status = HttpStatus.Failure
  result.version = HttpVersionError
  result.code = -1
  result.hdrs = newSeq[HttpHeader]()

  if len(data) == 0:
    return

  # Preserve ``data`` sequence in our object.
  shallowCopy(result.data, cast[seq[byte]](data))

  while index < len(data):
    let ps = responseSM.processHeaders(state, char(data[index]))
    result.state = ps
    case ps
    of 0x81:
      start = index
    of 0x82:
      if start == -1:
        break
      finish = index - 1
      when T is byte:
        let m = processVersion(cast[seq[char]](data), start, finish)
      else:
        let m = processVersion(data, start, finish)
      if m == HttpVersion.HttpVersionError:
        break
      result.version = m
      start = -1
    of 0x83:
      start = index
    of 0x84, 0x85:
      if start == -1:
        break
      finish = index - 1
      when T is byte:
        let m = processCode(cast[seq[char]](data), start, finish)
      else:
        let m = processCode(data, start, finish)
      if m == -1:
        break
      result.code = m
      if ps == 0x84:
        result.rsn = HttpHeaderPart(s: -1, e: -1)
      start = -1
    of 0x86:
      start = index
    of 0x87:
      if start == -1:
        break
      finish = index - 1
      result.rsn = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x88, 0x89, 0x8C, 0x8F:
      discard
    of 0x8A:
      start = index
    of 0x8B:
      if start == -1:
        break
      finish = index - 1
      hdr.name = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x8D:
      start = index
    of 0x8E:
      if start == -1:
        # empty header
        hdr.value = HttpHeaderPart(s: -1, e: -1)
      else:
        finish = index - 1
        hdr.value = HttpHeaderPart(s: start, e: finish)
      result.hdrs.add(hdr)
      start = -1
    of 0x9F:
      result.length = index + 1
      result.status = HttpStatus.Success
      break
    of 0xC0..0xCF:
      # error
      break
    of 0x00..0x0F:
      # data processing
      discard
    else:
      # must not be happened
      break
    inc(index)

template success*(reqresp: HttpReqRespHeader): bool =
  ## Returns ``true`` is ``reqresp`` was successfully parsed.
  reqresp.status == HttpStatus.Success

template failed*(reqresp: HttpReqRespHeader): bool =
  ## Returns ``true`` if ``reqresp`` parsing was failed.
  reqresp.status == HttpStatus.Failure

proc compare(data: seq[byte], header: HttpHeader, key: string): int =
  ## Case-insensitive comparison function.
  let length = header.name.e - header.name.s + 1
  result = length - len(key)
  if result == 0:
    var idx = 0
    for i in header.name.s..header.name.e:
      result = ord(toLowerAscii(char(data[i]))) - ord(toLowerAscii(key[idx]))
      if result != 0:
        return
      inc(idx)

proc contains*(reqresp: HttpReqRespHeader, header: string): bool =
  ## Return ``true``, if header with key ``header`` exists in `reqresp` object.
  result = false
  if reqresp.success():
    for item in reqresp.hdrs:
      if reqresp.data.compare(item, header) == 0:
        result = true

proc `[]`*(reqresp: HttpReqRespHeader, header: string): string =
  ## Retrieve HTTP header value from ``reqresp`` with key ``header``.
  if reqresp.success():
    for item in reqresp.hdrs:
      if reqresp.data.compare(item, header) == 0:
        if item.value.s == -1 and item.value.e == -1:
          result = ""
        else:
          result = cast[string](reqresp.data[item.value.s..item.value.e])
        break

iterator headers*(reqresp: HttpReqRespHeader,
                  key: string = ""): tuple[name: string, value: string] =
  ## Iterates over all or specific headers  in ``reqresp`` headers object.
  ## You can specify ``key` string to iterate only over headers which has key
  ## equal to ``key`` string.
  if reqresp.success():
    for item in reqresp.hdrs:
      if len(key) == 0:
        var name = cast[string](reqresp.data[item.name.s..item.name.e])
        var value: string
        if item.value.s == -1 and item.value.e == -1:
          value = ""
        else:
          value = cast[string](reqresp.data[item.value.s..item.value.e])
        yield (name, value)
      else:
        if reqresp.data.compare(item, key) == 0:
          var name = key
          var value: string
          if item.value.s == -1 and item.value.e == -1:
            value = ""
          else:
            value = cast[string](reqresp.data[item.value.s..item.value.e])
          yield (name, value)

proc uri*(request: HttpRequestHeader): string =
  ## Returns HTTP request URI as string from ``request``.
  if request.success():
    if request.url.s == -1 and request.url.e == -1:
      result = ""
    else:
      result = cast[string](request.data[request.url.s..request.url.e])

proc reason*(response: HttpResponseHeader): string =
  ## Returns HTTP reason string from ``response``.
  if response.success():
    if response.rsn.s == -1 and response.rsn.e == -1:
      result = ""
    else:
      result = cast[string](response.data[response.rsn.s..response.rsn.e])

proc len*(reqresp: HttpReqRespHeader): int =
  ## Returns number of headers in ``reqresp``.
  if reqresp.success():
    result = len(reqresp.hdrs)

proc size*(reqresp: HttpReqRespHeader): int =
  ## Returns size of HTTP headers in octets (bytes).
  if reqresp.success():
    result = reqresp.length

proc `$`*(version: HttpVersion): string =
  ## Return string representation of HTTP version ``version``.
  case version
  of HttpVersion09:
    result = "HTTP/0.9"
  of HttpVersion10:
    result = "HTTP/1.0"
  of HttpVersion11:
    result = "HTTP/1.1"
  of HttpVersion20:
    result = "HTTP/2.0"
  else:
    result = "HTTP/1.0"

{.push overflowChecks: off.}
proc contentLength*(reqresp: HttpReqRespHeader): int =
  ## Returns "Content-Length" header value as positive integer.
  ##
  ## If header is not present, ``0`` value will be returned, if value of header
  ## has non-integer value ``-1`` will be returned.
  result = -1
  if reqresp.success():
    let nstr = reqresp["Content-Length"]
    if len(nstr) == 0:
      result = 0
    else:
      let vstr = strip(nstr)
      result = 0
      for i in 0..<len(vstr):
        if vstr[i] in NUM:
          var r = result
          let digit = ord(vstr[i]) - ord('0')
          r = r * 10 + digit
          if r < result:
            # overflow
            result = -1
            break
          else:
            result = r
        else:
          result = -1
          break
{.pop.}

proc httpDate*(datetime: DateTime): string =
  ## Returns ``datetime`` formated as HTTP full date (RFC-822).
  ## ``Note``: ``datetime`` must be in UTC/GMT zone.
  result = datetime.format("ddd, dd MMM yyyy HH:mm:ss")
  result.add(" GMT")

proc httpDate*(): string {.inline.} =
  ## Returns current datetime formatted as HTTP full date (RFC-822).
  result = utc(now()).httpDate()

proc `$`*(m: HttpMethod): string =
  ## Returns string representation of HTTP method ``m``.
  case m
  of MethodGet:     "GET"
  of MethodPost:    "POST"
  of MethodHead:    "HEAD"
  of MethodPut:     "PUT"
  of MethodDelete:  "DELETE"
  of MethodTrace:   "TRACE"
  of MethodOptions: "OPTIONS"
  of MethodConnect: "CONNECT"
  of MethodPatch:   "PATCH"
  of MethodError:   "ERROR"

proc checkHeaderName*(value: string): bool =
  ## Validates ``value`` as `header field name` string and returns ``true``
  ## on success.
  if len(value) == 0:
    result = false
  else:
    result = true
    for ch in value:
      if ch notin HEADERNAME:
        result = false
        break

proc checkHeaderValue*(value: string): bool =
  ## Validates ``value`` as `header field value` string and returns ``true``
  ## on success.
  result = true
  for ch in value:
    if (ch == CR) or (ch == LF):
      result = false
      break
