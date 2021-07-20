#
#                   HTTP Utilities
#                 (c) Copyright 2018
#         Status Research & Development GmbH
#
#              Licensed under either of
#  Apache License, version 2.0, (LICENSE-APACHEv2)
#              MIT license (LICENSE-MIT)
import std/[times, strutils]
import stew/results

export results

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

  BSLASH = {'\\'}
  FSLASH = {'/'}
  COMMA = {','}
  DQUOTE = {'"'}
  EQUALS = {'='}
  SEMCOL = {';'}
  SPACEO = {'\x20'}
  HOTAB = {'\x09'}
  CHAR = {'\x00' .. '\x7F'}
  CTL = {'\x00' .. '\x1F'}
  SEPARATORS = {'(', ')', '<', '>', '@', ',', ';', ':',
                '\\', '"', '/', '[', ']', '?', '=', '{',
                '}'} + SPACEO + HOTAB
  LTOKEN = CHAR - CTL - SEPARATORS
  LSEP = SEPARATORS - BSLASH - DQUOTE - EQUALS - SEMCOL -
         SPACEO - HOTAB
  LSEP2 = LSEP - COMMA - FSLASH

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
    0x8B, 0x8B, 0x8B, 0x8B, 0x8B, 0x8B, 0x8C, 0xC6, 0x8B, 0x8B, 0x8B, 0x0A, 0xCF, 0xCF, 0xCF, 0xCF, # s0a: 1st space
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
    0xC3, 0x86, 0x86, 0x86, 0x86, 0x86, 0x87, 0xC3, 0x86, 0x86, 0x86, 0x86, 0xCF, 0xCF, 0xCF, 0xCF, # s05: first reason char
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

  # Legend:
  # 0x81 - start of disposition type
  # 0x82 - end of disposition type or end of token value.
  # 0x83 - start of parameter name
  # 0x84 - end of parameter name
  # 0x85 - start of tokenized parameter value
  # 0x86 - end of tokenized parameter value
  # 0x87 - double quote
  # 0x88 - start of quoted parameter value
  # 0x89 - 0x8A - escaped quote
  # 0x8B - end of quoted parameter value
  # 0x8C - semicolon and spaces
  # [0xC0 - 0xCC] error values

  #    *  LTOK  LSEP  BSLA  DQUO  EQUA  SEMC  SPAC  HOTA
  contdispSM = [
    0xC0, 0x81, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, # s0: start of disposition-type
    0xC1, 0x01, 0xC1, 0xC1, 0xC1, 0xC1, 0x82, 0xC1, 0xC1, # s1: disposition-type
    0xC2, 0x83, 0xC2, 0xC2, 0xC2, 0xC2, 0xC2, 0x02, 0x02, # s2: semicolon and spaces
    0xC3, 0x03, 0xC1, 0xC1, 0xC1, 0x84, 0xC1, 0xC1, 0xC1, # s3: parm-name
    0xC4, 0x85, 0xC4, 0xC4, 0x87, 0xC4, 0x8D, 0xC4, 0xC4, # s4: =
    0xC5, 0x05, 0xC5, 0xC5, 0xC5, 0xC5, 0x86, 0xC5, 0xC5, # s5: parm-value as token start
    0xC6, 0x83, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0x06, 0x06, # s6: parm-value as token finish
    0xC7, 0x88, 0x88, 0x88, 0x8B, 0x88, 0x88, 0x88, 0x88, # s7: double quote
    0xC8, 0x08, 0x08, 0x89, 0x8B, 0x08, 0x08, 0x08, 0x08, # s8: quoted parm-value
    0xC9, 0x08, 0x08, 0x08, 0x8A, 0x08, 0x08, 0x08, 0x08, # s9: middle double quote
    0xCA, 0x08, 0x08, 0x89, 0x8B, 0x08, 0x08, 0x08, 0x08, # sA: quoted parm-value
    0xCB, 0xCB, 0xCB, 0xCB, 0xCB, 0xCB, 0x8C, 0xCB, 0xCB, # sB: finish double quote
    0xCC, 0x83, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0x0C, 0x0C, # sC: semicolon and spaces
    0xCD, 0x83, 0xCD, 0xCD, 0xCD, 0xCD, 0xCD, 0x0D, 0x0D, # sD: semicolon and spaces
  ]

  #     *  LTOKN  LSEP2      /      \      ,      ;      "      =  SPACE
  acceptSM = [
    0xE00, 0x801, 0xE00, 0xE00, 0xE00, 0x000, 0xE00, 0xE00, 0xE00, 0xE00, # s00: start of media-type
    0xE01, 0x001, 0xE01, 0x802, 0xE01, 0xE01, 0xE01, 0xE01, 0xE01, 0xE01, # s01: media-type and forward slash
    0xE02, 0x803, 0xE02, 0xE02, 0xE02, 0xE02, 0xE02, 0xE02, 0xE02, 0xE02, # s02: forward slash
    0xE03, 0x003, 0xE03, 0xE03, 0xE03, 0x805, 0x806, 0xE03, 0xE03, 0x804, # s03: media-subtype
    0xE04, 0xE04, 0xE04, 0xE04, 0xE04, 0x805, 0x806, 0xE04, 0xE04, 0x004, # s04: spaces
    0xE05, 0x801, 0xE05, 0xE05, 0xE05, 0xE05, 0xE05, 0xE05, 0xE05, 0x005, # s05: comma and spaces
    0xE06, 0x807, 0xE06, 0xE06, 0xE06, 0xE06, 0xE06, 0xE06, 0xE06, 0x006, # s06: semicolon and spaces
    0xE07, 0x007, 0xE07, 0xE07, 0xE07, 0xE07, 0xE07, 0xE07, 0x808, 0xE07, # s07: param-name
    0xE08, 0x80A, 0xE08, 0xE08, 0xE08, 0x809, 0x80D, 0x80E, 0xE08, 0xE08, # s08: =
    0xE09, 0x801, 0xE09, 0xE09, 0xE09, 0xE09, 0xE09, 0xE09, 0xE09, 0x009, # s09: comma and spaces after <param_name>=,
    0xE0A, 0x00A, 0xE0A, 0xE0A, 0xE0A, 0x80C, 0x80B, 0xE0A, 0xE0A, 0xE0A, # s0A: param value as token
    0xE0B, 0x807, 0xE0B, 0xE0B, 0xE0B, 0xE0B, 0xE0B, 0xE0B, 0xE0B, 0x00B, # s0B: spaces after ;
    0xE0C, 0x801, 0xE0C, 0xE0C, 0xE0C, 0xE0C, 0xE0C, 0xE0C, 0xE0C, 0x00C, # s0C: spaces after ,
    0xE0D, 0x807, 0xE0D, 0xE0D, 0xE0D, 0xE0D, 0xE0D, 0xE0D, 0xE0D, 0x00D, # s0D: spaces after =;
    0xE0E, 0x80F, 0x80F, 0x80F, 0x810, 0x80F, 0x80F, 0x812, 0x80F, 0x80F, # s0E: starting double quote
    0xE0F, 0x00F, 0x00F, 0x00F, 0x810, 0x00F, 0x00F, 0x812, 0x00F, 0x00F, # s0F: quoted param-value
    0xE10, 0x00F, 0x00F, 0x00F, 0x00F, 0x00F, 0x00F, 0x811, 0x00F, 0x00F, # s10: backslash
    0xE11, 0x00F, 0x00F, 0x00F, 0x810, 0x00F, 0x00F, 0x812, 0x00F, 0x00F, # s11: double quote after backslash
    0xE12, 0xE12, 0xE12, 0xE12, 0xE12, 0x814, 0x813, 0xE12, 0xE12, 0xE12, # s12: finish double quote
    0xE13, 0x807, 0xE13, 0xE13, 0xE13, 0xE13, 0xE13, 0xE13, 0xE13, 0x013, # s13: [";] and spaces
    0xE14, 0x801, 0xE14, 0xE14, 0xE14, 0xE14, 0xE14, 0xE14, 0xE14, 0x014  # s14: [",] and spaces
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

  HttpHeadersList* = object
    ## HTTP request headers list
    data: seq[byte]
    state*: int
    status*: HttpStatus
    hdrs: seq[HttpHeader]
    length*: int

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

  ContentDispositionHeader* = object
    data: seq[byte]
    state*: int
    status*: HttpStatus
    disptype: HttpHeaderPart
    flds: seq[HttpHeader]

  AcceptMediaType* = object
    mtype*: HttpHeaderPart
    stype*: HttpHeaderPart
    params*: seq[HttpHeader]

  AcceptHeader* = object
    data: seq[byte]
    state*: int
    status*: HttpStatus
    mediaTypes*: seq[AcceptMediaType]

  HttpReqRespHeader* = HttpRequestHeader | HttpResponseHeader | HttpHeadersList

  BChar* = byte | char

template processHeaders(sm: untyped, state: var int, ch: char): int =
  let code =
    case ch
    of ALPHA:
      1
    of NUM:
      2
    of TOKENURI:
      3
    of TOKENONLY:
      4
    of URIONLY:
      5
    of CR:
      6
    of LF:
      7
    of COLON:
      8
    of SLASH:
      9
    of DOT:
      10
    of SPACE:
      11
    else:
      0
  let newstate = sm[(state shl 4) + code]
  state = newstate and 0x0F
  newstate

template processDisposition(sm: untyped, state: var int, ch: char): int =
  let code =
    case ch
    of LTOKEN:
      1
    of LSEP:
      2
    of BSLASH:
      3
    of DQUOTE:
      4
    of EQUALS:
      5
    of SEMCOL:
      6
    of SPACEO:
      7
    of HOTAB:
      8
    else:
      0
  let newstate = sm[(state shl 3) + state + code]
  state = newstate and 0x0F
  newstate

template processAcceptHeader(sm: untyped, state: var int, ch: char): int =
  let code =
    case ch
    of LTOKEN:
      1
    of LSEP2:
      2
    of FSLASH:
      3
    of BSLASH:
      4
    of COMMA:
      5
    of SEMCOL:
      6
    of DQUOTE:
      7
    of EQUALS:
      8
    of SPACE:
      9
    else:
      0
  let newstate = sm[(state shl 3) + (state shl 1) + code]
  state = newstate and 0xFF
  newstate

proc processMethod[T: Bchar](data: openarray[T], s, e: int): HttpMethod =
  let length = e - s + 1
  case char(data[s])
  of 'G':
    if length == 3:
      if char(data[s + 1]) == 'E' and char(data[s + 2]) == 'T':
        return MethodGet
  of 'H':
    if length == 4:
      if char(data[s + 1]) == 'E' and char(data[s + 2]) == 'A' and
         char(data[s + 3]) == 'D':
        return MethodHead
  of 'P':
    if length == 3:
      if char(data[s + 1]) == 'U' and char(data[s + 2]) == 'T':
        return MethodPut
    elif length == 4:
      if char(data[s + 1]) == 'O' and char(data[s + 2]) == 'S' and
         char(data[s + 3]) == 'T':
        return MethodPost
    elif length == 5:
      if char(data[s + 1]) == 'A' and char(data[s + 2]) == 'T' and
         char(data[s + 3]) == 'C' and char(data[s + 4]) == 'H':
        return MethodPatch
  of 'D':
    if length == 6:
      if char(data[s + 1]) == 'E' and char(data[s + 2]) == 'L' and
         char(data[s + 3]) == 'E' and char(data[s + 4]) == 'T' and
         char(data[s + 5]) == 'E':
        return MethodDelete
  of 'T':
    if length == 5:
      if char(data[s + 1]) == 'R' and char(data[s + 2]) == 'A' and
         char(data[s + 3]) == 'C' and char(data[s + 4]) == 'E':
       return MethodTrace
  of 'O':
    if length == 7:
      if char(data[s + 1]) == 'P' and char(data[s + 2]) == 'T' and
         char(data[s + 3]) == 'I' and char(data[s + 4]) == 'O' and
         char(data[s + 5]) == 'N' and char(data[s + 6]) == 'S':
        return MethodOptions
  of 'C':
    if length == 7:
      if char(data[s + 1]) == 'O' and char(data[s + 2]) == 'N' and
         char(data[s + 3]) == 'N' and char(data[s + 4]) == 'E' and
         char(data[s + 5]) == 'C' and char(data[s + 6]) == 'T':
        return MethodConnect
  else:
    discard

  return HttpMethod.MethodError

proc processVersion[T: BChar](data: openarray[T], s, e: int): HttpVersion =
  let length = e - s + 1
  if length == 8:
    if char(data[s]) == 'H' and char(data[s + 1]) == 'T' and
       char(data[s + 2]) == 'T' and char(data[s + 3]) == 'P' and
       char(data[s + 4]) == '/':
      if char(data[s + 5]) == '1' and char(data[s + 6]) == '.':
        if char(data[s + 7]) == '0':
          return HttpVersion10
        elif char(data[s + 7]) == '1':
          return HttpVersion11
      elif char(data[s + 5]) == '0' and char(data[s + 6]) == '.':
        if char(data[s + 7]) == '9':
          return HttpVersion09
      elif char(data[s + 5]) == '2' and char(data[s + 6]) == '.':
        if char(data[s + 7]) == '0':
          return HttpVersion20
  return HttpVersionError

proc processCode[T: BChar](data: openarray[T], s, e: int): int =
  var res = -1
  let length = e - s + 1
  if length == 3:
    res = (ord(data[s]) - ord('0')) * 100 +
          (ord(data[s + 1]) - ord('0')) * 10 +
           ord(data[s + 2]) - ord('0')
  res

proc parseRequest*[T: BChar](data: openarray[T],
                             makeCopy: bool): HttpRequestHeader =
  ## Parse sequence of characters or bytes ``data`` as HTTP request header.
  ##
  ## If `makeCopy` flag is ``true``, procedure will create a copy of ``data``
  ## in result.
  ##
  ## Returns `HttpRequestHeader` instance.
  var
    index = 0
    state = 0
    start = -1
    finish = 0
    hdr: HttpHeader

  var res = HttpRequestHeader(
    status: HttpStatus.Failure,
    version: HttpVersionError,
    meth: MethodError,
    hdrs: newSeq[HttpHeader]()
  )

  if len(data) == 0:
    return res

  if makeCopy:
    # Make copy of ``data`` sequence in our result object.
    res.data = newSeq[byte](len(data))
    copyMem(addr res.data[0], unsafeAddr data[0], len(data))

  while index < len(data):
    let ps = requestSM.processHeaders(state, char(data[index]))
    res.state = ps
    case ps
    of 0x81:
      start = index
    of 0x82:
      if start == -1:
        break
      finish = index - 1
      let m = processMethod(data, start, finish)
      if m == HttpMethod.MethodError:
        break
      res.meth = m
      start = -1
    of 0x83:
      start = index
    of 0x84:
      if start == -1:
        break
      finish = index - 1
      res.url = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x85:
      start = index
    of 0x86:
      if start == -1:
        break
      finish = index - 1
      let m = processVersion(data, start, finish)
      if m == HttpVersion.HttpVersionError:
        break
      res.version = m
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
      res.hdrs.add(hdr)
      start = -1
    of 0x8E:
      res.length = index + 1
      res.status = HttpStatus.Success
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

  res

proc parseRequest*[T: BChar](data: seq[T]): HttpRequestHeader =
  ## Parse sequence of characters or bytes as HTTP request header.
  ##
  ## Note: to prevent unnecessary allocations source array ``data`` will be
  ## be shallow copied to result and all parsed fields will have references to
  ## this buffer. If you plan to change contents of ``data`` while parsing
  ## request and/or processing headers, please make a real copy of ``data`` and
  ## pass copy to ``parseRequest(data)``.
  ##
  ## Returns `HttpRequestHeader` instance.
  var res = parseRequest(data, false)
  shallowCopy(res.data, cast[seq[byte]](data))
  res

proc parseHeaders*[T: BChar](data: openarray[T],
                             makeCopy: bool): HttpHeadersList =
  ## Parse sequence of characters or bytes ``data`` as HTTP headers list.
  ##
  ## If `makeCopy` flag is ``true``, procedure will create a copy of ``data``
  ## in result.
  ##
  ## Returns `HttpHeadersList` instance.
  var
    index = 0
    state = 8
    start = 0
    finish = 0
    hdr: HttpHeader

  var res = HttpHeadersList(
    status: HttpStatus.Failure,
    hdrs: newSeq[HttpHeader]()
  )

  if len(data) == 0:
    return res

  if makeCopy:
    # Make copy of ``data`` sequence in our result object.
    res.data = newSeq[byte](len(data))
    copyMem(addr res.data[0], unsafeAddr data[0], len(data))

  while index < len(data):
    let ps = requestSM.processHeaders(state, char(data[index]))
    res.state = ps
    case ps
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
      res.hdrs.add(hdr)
      start = -1
    of 0x8E:
      res.length = index + 1
      res.status = HttpStatus.Success
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
  res

proc parseHeaders*[T: BChar](data: seq[T]): HttpHeadersList =
  ## Parse sequence of characters or bytes as HTTP headers list.
  ##
  ## Note: to prevent unnecessary allocations source array ``data`` will be
  ## be shallow copied to result and all parsed fields will have references to
  ## this buffer. If you plan to change contents of ``data`` while parsing
  ## request and/or processing headers, please make a real copy of ``data`` and
  ## pass copy to ``parseHeaders(data)``.
  ##
  ## Returns `HttpHeadersList` instance.
  var res = parseHeaders(data, false)
  shallowCopy(res.data, cast[seq[byte]](data))
  res

proc parseResponse*[T: BChar](data: openarray[T],
                                  makeCopy: bool): HttpResponseHeader =
  ## Parse sequence of characters or bytes as HTTP response header.
  ##
  ## If `makeCopy` flag is ``true``, procedure will create a copy of ``data``
  ## in result.
  ##
  ## Returns `HttpResponseHeader` instance.
  var
    index = 0
    state = 0
    start = -1
    finish = 0
    hdr: HttpHeader

  var res = HttpResponseHeader(
    status: HttpStatus.Failure,
    version: HttpVersionError,
    code: -1,
    hdrs: newSeq[HttpHeader]()
  )

  if len(data) == 0:
    return res

  if makeCopy:
    # Make copy of ``data`` sequence in our result object.
    res.data = newSeq[byte](len(data))
    copyMem(addr res.data[0], unsafeAddr data[0], len(data))

  while index < len(data):
    let ps = responseSM.processHeaders(state, char(data[index]))
    res.state = ps
    case ps
    of 0x81:
      start = index
    of 0x82:
      if start == -1:
        break
      finish = index - 1
      let m = processVersion(data, start, finish)
      if m == HttpVersion.HttpVersionError:
        break
      res.version = m
      start = -1
    of 0x83:
      start = index
    of 0x84, 0x85:
      if start == -1:
        break
      finish = index - 1
      let m = processCode(data, start, finish)
      if m == -1:
        break
      res.code = m
      if ps == 0x84:
        res.rsn = HttpHeaderPart(s: -1, e: -1)
      start = -1
    of 0x86:
      start = index
    of 0x87:
      if start == -1:
        res.rsn = HttpHeaderPart(s: -1, e: -1)
      else:
        finish = index - 1
        res.rsn = HttpHeaderPart(s: start, e: finish)
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
      res.hdrs.add(hdr)
      start = -1
    of 0x9F:
      res.length = index + 1
      res.status = HttpStatus.Success
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
  res

proc parseResponse*[T: BChar](data: seq[T]): HttpResponseHeader =
  ## Parse sequence of characters or bytes as HTTP response header.
  ##
  ## Note: to prevent unnecessary allocations source array ``data`` will be
  ## be shallow copied to result and all parsed fields will have references to
  ## this buffer. If you plan to change contents of ``data`` while parsing
  ## request and/or processing headers, please make a real copy of ``data`` and
  ## pass copy to ``parseResponse(data)``.
  ##
  ## Returns `HttpResponseHeader` instance.
  var res = parseResponse(data, false)
  shallowCopy(res.data, cast[seq[byte]](data))
  res

proc parseDisposition*[T: BChar](data: openarray[T],
                                 makeCopy: bool): ContentDispositionHeader =
  ## Parse sequence of characters or bytes of HTTP ``Content-Disposition``
  ## header according to RFC6266.
  ##
  ## TODO: Support extended `*` values.
  ##
  ## If `makeCopy` flag is ``true``, procedure will create a copy of ``data``
  ## in result.
  ##
  ## Returns `ContentDispositionHeader` instance.
  var
    index = 0
    state = 0
    start = -1
    finish = 0
    hdr: HttpHeader

  var res = ContentDispositionHeader(
    status: HttpStatus.Failure,
    disptype: HttpHeaderPart(),
    flds: newSeq[HttpHeader]()
  )

  if len(data) == 0:
    return res

  if makeCopy:
    # Make copy of ``data`` sequence in our result object.
    res.data = newSeq[byte](len(data))
    copyMem(addr res.data[0], unsafeAddr data[0], len(data))

  while index < len(data):
    let ps = contdispSM.processDisposition(state, char(data[index]))
    res.state = ps
    case ps
    of 0x81:
      start = index
    of 0x82:
      if start == -1:
        break
      finish = index - 1
      res.disptype = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x83:
      start = index
    of 0x84:
      if start == -1:
        break
      finish = index - 1
      hdr.name = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x85:
      start = index
    of 0x86:
      if start == -1:
        break
      finish = index - 1
      hdr.value = HttpHeaderPart(s: start, e: finish)
      res.flds.add(hdr)
      start = -1
    of 0x87:
      start = index + 1
    of 0x88:
      start = index
    of 0x89, 0x8A:
      discard
    of 0x8B:
      if start == -1:
        break
      finish = index - 1
      hdr.value = HttpHeaderPart(s: start, e: finish)
      res.flds.add(hdr)
    of 0x8C:
      discard
    of 0x8D:
      hdr.value = HttpHeaderPart(s: index, e: index - 1)
      res.flds.add(hdr)
    of 0x00..0x0D:
      discard
    of 0xC0..0xCD:
      break
    else:
      break
    inc(index)

  res.status =
    case res.state
    of 0x01, 0x81:
      if start == -1:
        HttpStatus.Failure
      else:
        res.disptype = HttpHeaderPart(s: start, e: index - 1)
        HttpStatus.Success
    of 0x84:
      hdr.value = HttpHeaderPart(s: index, e: index - 1)
      res.flds.add(hdr)
      HttpStatus.Success
    of 0x05, 0x85:
      if start == -1:
        HttpStatus.Failure
      else:
        hdr.value = HttpHeaderPart(s: start, e: index - 1)
        res.flds.add(hdr)
        HttpStatus.Success
    of 0x0B, 0x8B:
      HttpStatus.Success
    else:
      HttpStatus.Failure

  if res.status == HttpStatus.Success:
    res
  else:
    ContentDispositionHeader(status: HttpStatus.Failure)

proc parseDisposition*[T: BChar](data: seq[T]): ContentDispositionHeader =
  ## Parse sequence of characters or bytes of HTTP ``Content-Disposition``
  ## header according to RFC6266.
  ##
  ## Note: to prevent unnecessary allocations source array ``data`` will be
  ## be shallow copied to result and all parsed fields will have references to
  ## this buffer. If you plan to change contents of ``data`` while parsing
  ## request and/or processing headers, please make a real copy of ``data`` and
  ## pass copy to ``parseDisposition(data)``.
  ##
  ## Returns `ContentDispositionHeader` instance.
  var res = parseDisposition(data, false)
  shallowCopy(res.data, cast[seq[byte]](data))
  res

proc parseAcceptHeader*[T: BChar](data: openarray[T],
                                  makeCopy: bool): AcceptHeader =
  var
    index = 0
    state = 0
    start = -1
    finish = 0
    hdr: HttpHeader
    mtype: AcceptMediaType

  var res = AcceptHeader(status: HttpStatus.Failure)

  if len(data) == 0:
    return res

  if makeCopy:
    # Make copy of ``data`` sequence in our result object.
    res.data = newSeq[byte](len(data))
    copyMem(addr res.data[0], unsafeAddr data[0], len(data))

  while index < len(data):
    let ps = acceptSM.processAcceptHeader(state, char(data[index]))
    echo "index = ", index, " char = [", char(data[index]), "] ps = ", toHex(ps)
    res.state = ps
    case ps
    of 0x801:
      mtype = AcceptMediaType()
      start = index
    of 0x802:
      if start == -1:
        mtype.mtype = HttpHeaderPart(s: -1, e: -1)
        break
      finish = index - 1
      mtype.mtype = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x803:
      start = index
    of 0x804, 0x805, 0x806:
      if start == -1:
        mtype.stype = HttpHeaderPart(s: -1, e: -1)
        break
      finish = index - 1
      mtype.stype = HttpHeaderPart(s: start, e: finish)
      start = -1
      if ps == 0x805:
        res.mediaTypes.add(mtype)
    of 0x807:
      hdr = HttpHeader()
      start = index
    of 0x808:
      if start == -1:
        hdr.name = HttpHeaderPart(s: -1, e: -1)
        break
      finish = index - 1
      hdr.name = HttpHeaderPart(s: start, e: finish)
      start = -1
    of 0x809:
      discard
    of 0x80A:
      start = index
    of 0x80B, 0x80C:
      if start == -1:
        hdr.value = HttpHeaderPart(s: -1, e: -1)
        break
      finish = index - 1
      hdr.value = HttpHeaderPart(s: start, e: finish)
      mtype.params.add(hdr)
      start = -1
      if ps == 0x80C:
        res.mediaTypes.add(mtype)
    of 0x80D:
      hdr.value = HttpHeaderPart(s: index, e: index - 1)
      mtype.params.add(hdr)
      start = -1
    of 0x80E:
      discard
    of 0x80F:
      start = index
    of 0x810, 0x811:
      discard
    of 0x812:
      if start == -1:
        hdr.value = HttpHeaderPart(s: -1, e: -1)
        break
      finish = index - 1
      hdr.value = HttpHeaderPart(s: start, e: finish)
      mtype.params.add(hdr)
      start = -1
    of 0x814:
      res.mediaTypes.add(mtype)
    of 0x000 .. 0x014:
      discard
    else:
      break
    inc(index)

  res.status =
    case res.state
    of 0x803, 0x003:
      if start == -1:
        HttpStatus.Failure
      else:
        finish = index - 1
        mtype.stype = HttpHeaderPart(s: start, e: finish)
        res.mediaTypes.add(mtype)
        HttpStatus.Success
    of 0x808, 0x008:
      hdr.value = HttpHeaderPart(s: index, e: index - 1)
      mtype.params.add(hdr)
      res.mediaTypes.add(mtype)
      HttpStatus.Success
    of 0x80A, 0x00A:
      if start == -1:
        HttpStatus.Failure
      else:
        finish = index - 1
        hdr.value = HttpHeaderPart(s: start, e: finish)
        mtype.params.add(hdr)
        res.mediaTypes.add(mtype)
        HttpStatus.Success
    of 0x812:
      res.mediaTypes.add(mtype)
      HttpStatus.Success
    else:
      HttpStatus.Failure

  if res.status == HttpStatus.Success:
    res
  else:
    AcceptHeader(status: HttpStatus.Failure)

template success*(reqresp: HttpReqRespHeader | ContentDispositionHeader |
                  AcceptHeader): bool =
  ## Returns ``true`` is ``reqresp`` was successfully parsed.
  reqresp.status == HttpStatus.Success

template failed*(reqresp: HttpReqRespHeader | ContentDispositionHeader |
                 AcceptHeader): bool =
  ## Returns ``true`` if ``reqresp`` parsing was failed.
  reqresp.status == HttpStatus.Failure

proc compare(data: openarray[byte], header: HttpHeader, key: string): int =
  ## Case-insensitive comparison function.
  let length = header.name.e - header.name.s + 1
  var res = length - len(key)
  if res == 0:
    var idx = 0
    for i in header.name.s..header.name.e:
      res = ord(toLowerAscii(char(data[i]))) - ord(toLowerAscii(key[idx]))
      if res != 0:
        return res
      inc(idx)
  res

proc contains*(reqresp: HttpReqRespHeader, header: string): bool =
  ## Return ``true``, if header with key ``header`` exists in `reqresp` object.
  if reqresp.success():
    for item in reqresp.hdrs:
      if reqresp.data.compare(item, header) == 0:
        return true
  return false

proc toString(data: openarray[byte], start, stop: int): string =
  ## Slice a raw data blob into a string
  ## This is an inclusive slice
  ## The output string is null-terminated for raw C-compat
  let length = stop - start + 1
  var res = newString(length)
  if length > 0:
    copyMem(addr res[0], unsafeAddr data[start], length)
  res

proc `[]`*(reqresp: HttpReqRespHeader, header: string): string =
  ## Retrieve HTTP header value from ``reqresp`` with key ``header``.
  if reqresp.success():
    for item in reqresp.hdrs:
      if reqresp.data.compare(item, header) == 0:
        if item.value.s == -1 and item.value.e == -1:
          return ""
        else:
          return reqresp.data.toString(item.value.s, item.value.e)
  ""

iterator headers*(reqresp: HttpReqRespHeader,
                  key: string = ""): tuple[name: string, value: string] =
  ## Iterates over all or specific headers  in ``reqresp`` headers object.
  ## You can specify ``key` string to iterate only over headers which has key
  ## equal to ``key`` string.
  if reqresp.success():
    for item in reqresp.hdrs:
      if len(key) == 0:
        let name = reqresp.data.toString(item.name.s, item.name.e)
        let value =
          if item.value.s == -1 and item.value.e == -1:
            ""
          else:
            reqresp.data.toString(item.value.s, item.value.e)
        yield (name, value)
      else:
        if reqresp.data.compare(item, key) == 0:
          let name = key
          let value =
            if item.value.s == -1 and item.value.e == -1:
              ""
            else:
              reqresp.data.toString(item.value.s, item.value.e)
          yield (name, value)

iterator headers*(reqresp: HttpReqRespHeader,
                  buffer: openarray[byte],
                  key: string = ""): tuple[name: string, value: string] =
  ## Iterates over all or specific headers  in ``reqresp`` headers object.
  ## You can specify ``key` string to iterate only over headers which has key
  ## equal to ``key`` string.
  if reqresp.success():
    for item in reqresp.hdrs:
      if len(key) == 0:
        let name = buffer.toString(item.name.s, item.name.e)
        let value =
          if item.value.s == -1 and item.value.e == -1:
            ""
          else:
            buffer.toString(item.value.s, item.value.e)
        yield (name, value)
      else:
        if buffer.compare(item, key) == 0:
          let name = key
          let value =
            if item.value.s == -1 and item.value.e == -1:
              ""
            else:
              buffer.toString(item.value.s, item.value.e)
          yield (name, value)

iterator fields*(header: ContentDispositionHeader): tuple[name: string,
                                                          value: string] =
  if header.success():
    for item in header.flds:
      var name = header.data.toString(item.name.s, item.name.e)
      var value =
        if item.value.s == -1 and item.value.e == -1:
          ""
        else:
          header.data.toString(item.value.s, item.value.e)
      yield(name, value.replace("\\\"", "\""))

iterator fields*(header: ContentDispositionHeader,
                 buffer: openarray[byte]): tuple[name: string, value: string] =
  if header.success():
    for item in header.flds:
      var name = buffer.toString(item.name.s, item.name.e)
      var value =
        if item.value.s == -1 and item.value.e == -1:
          ""
        else:
          buffer.toString(item.value.s, item.value.e)
      yield(name, value.replace("\\\"", "\""))

proc mediaType*(s: AcceptMediaType, buffer: openarray[byte]): string =
  ## Returns media type/subtype as string.
  buffer.toString(s.mtype.s, s.mtype.e) & "/" &
    buffer.toString(s.stype.s, s.stype.e)

iterator types*(header: AcceptHeader): string =
  ## Iterate over AcceptHeader media type/subtypes.
  if header.success():
    for item in header.mediaTypes:
      yield item.mediaType(header.data)

iterator types*(header: AcceptHeader, buffer: openarray[byte]): string =
  ## Iterate over AcceptHeader media type/subtypes.
  if header.success():
    for item in header.mediaTypes:
      yield item.mediaType(buffer)

iterator tuples*(header: AcceptHeader): tuple[mediaType: string,
                                              param: string,
                                              value: string] =
  if header.success():
    for item in header.mediaTypes:
      let mtype = item.mediaType(header.data)
      if len(item.params) == 0:
        yield (mtype, "", "")
      else:
        for param in item.params:
          let paramName = header.data.toString(param.name.s, param.name.e)
          let paramValue = header.data.toString(param.value.s, param.value.e)
          yield (mtype, paramName, paramValue)

iterator tuples*(header: AcceptHeader,
                 buffer: openarray[byte]): tuple[mediaType: string,
                                                 param: string,
                                                 value: string] =
  if header.success():
    for item in header.mediaTypes:
      let mtype = item.mediaType(buffer)
      if len(item.params) == 0:
        yield (mtype, "", "")
      else:
        for param in item.params:
          let paramName = buffer.toString(param.name.s, param.name.e)
          let paramValue = buffer.toString(param.value.s, param.value.e)
          yield (mtype, paramName, paramValue)

proc uri*(request: HttpRequestHeader): string =
  ## Returns HTTP request URI as string from ``request``.
  if request.success():
    if request.url.s == -1 and request.url.e == -1:
      ""
    else:
      request.data.toString(request.url.s, request.url.e)
  else:
    ""

proc uri*(request: HttpRequestHeader, buffer: openarray[byte]): string =
  ## Returns HTTP request URI as string from ``request``.
  if request.success():
    if request.url.s == -1 and request.url.e == -1:
      ""
    else:
      buffer.toString(request.url.s, request.url.e)
  else:
    ""

proc reason*(response: HttpResponseHeader): string =
  ## Returns HTTP reason string from ``response``.
  if response.success():
    if response.rsn.s == -1 and response.rsn.e == -1:
      ""
    else:
      response.data.toString(response.rsn.s, response.rsn.e)
  else:
    ""

proc reason*(response: HttpResponseHeader, buffer: openarray[byte]): string =
  ## Returns HTTP reason string from ``response``.
  if response.success():
    if response.rsn.s == -1 and response.rsn.e == -1:
      ""
    else:
      buffer.toString(response.rsn.s, response.rsn.e)
  else:
    ""

proc dispositionType*(header: ContentDispositionHeader): string =
  ## Returns disposition type of ``Content-Disposition`` header.
  if header.success():
    if header.disptype.s == -1 and header.disptype.e == -1:
      ""
    else:
      header.data.toString(header.disptype.s, header.disptype.e)
  else:
    ""

proc dispositionType*(header: ContentDispositionHeader,
               buffer: openarray[byte]): string =
  ## Returns disposition type of ``Content-Disposition`` header.
  if header.success():
    if header.disptype.s == -1 and header.disptype.e == -1:
      ""
    else:
      buffer.toString(header.disptype.s, header.disptype.e)
  else:
    ""

proc len*(reqresp: HttpReqRespHeader): int =
  ## Returns number of headers in ``reqresp``.
  if reqresp.success():
    len(reqresp.hdrs)
  else:
    0

proc size*(reqresp: HttpReqRespHeader): int =
  ## Returns size of HTTP headers in octets (bytes).
  if reqresp.success():
    reqresp.length
  else:
    0

proc `$`*(version: HttpVersion): string =
  ## Return string representation of HTTP version ``version``.
  case version
  of HttpVersion09:
    "HTTP/0.9"
  of HttpVersion10:
    "HTTP/1.0"
  of HttpVersion11:
    "HTTP/1.1"
  of HttpVersion20:
    "HTTP/2.0"
  else:
    "HTTP/1.0"

{.push overflowChecks: off.}
proc contentLength*(reqresp: HttpReqRespHeader): int =
  ## Returns "Content-Length" header value as positive integer.
  ##
  ## If header is not present, ``0`` value will be returned, if value of header
  ## has non-integer value ``-1`` will be returned.
  const
    MaxValue = high(int) div 10
    MaxNumber = high(int) mod 10
  if reqresp.success():
    let nstr = reqresp["Content-Length"]
    if len(nstr) == 0:
      0
    else:
      let vstr = strip(nstr)
      var res = 0
      for i in 0..<len(vstr):
        let ch = vstr[i]
        if ch notin NUM:
          return -1
        let digit = ord(ch) - ord('0')
        if (res > MaxValue) or (res == MaxValue and digit > MaxNumber):
          # overflow
          return -1
        res = res * 10 + digit
      res
  else:
    -1
{.pop.}

proc httpDate*(datetime: DateTime): string =
  ## Returns ``datetime`` formated as HTTP full date (RFC-822).
  ## ``Note``: ``datetime`` must be in UTC/GMT zone.
  var res = datetime.format("ddd, dd MMM yyyy HH:mm:ss")
  res.add(" GMT")
  res

proc httpDate*(): string {.inline.} =
  ## Returns current datetime formatted as HTTP full date (RFC-822).
  utc(now()).httpDate()

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
    false
  else:
    var res = true
    for ch in value:
      if ch notin HEADERNAME:
        res = false
        break
    res

proc checkHeaderValue*(value: string): bool =
  ## Validates ``value`` as `header field value` string and returns ``true``
  ## on success.
  var res = true
  for ch in value:
    if (ch == CR) or (ch == LF):
      res = false
      break
  res

proc getQvalue*(value: string): Result[float, cstring] =
  ## Parse quality value string and returns floating point number. If quality
  ## value string format is not acceptable error will be returned.
  ## https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.9
  const
    IncorrectQValue = cstring"Incorrect q-value"
    IncorrectQValueLength = cstring"Incorrect q-value length"
  case len(value)
  of 0:
    ok(1.0)
  of 1:
    case value[0]
    of '0':
      ok(0.0)
    of '1':
      ok(1.0)
    else:
      err(IncorrectQValue)
  of 2:
    if value[1] != '.':
      return err(IncorrectQValue)
    case value[0]
    of '0':
      ok(0.0)
    of '1':
      ok(1.0)
    else:
      err(IncorrectQValue)
  of 3:
    if value[1] != '.':
      return err(IncorrectQValue)
    case value[0]
    of '0':
      if isDigit(value[2]):
        return ok(parseFloat(value))
      err(IncorrectQValue)
    of '1':
      if value[2] == '0':
        return ok(1.0)
      err(IncorrectQValue)
    else:
      err(IncorrectQValue)
  of 4:
    if value[1] != '.':
      return err(IncorrectQValue)
    case value[0]
    of '0':
      if isDigit(value[2]) and isDigit(value[3]):
        return ok(parseFloat(value))
      err(IncorrectQValue)
    of '1':
      if (value[2] == '0') and (value[3] == '0'):
        return ok(1.0)
      err(IncorrectQValue)
    else:
      err(IncorrectQValue)
  of 5:
    if value[1] != '.':
      return err(IncorrectQValue)
    case value[0]
    of '0':
      if isDigit(value[2]) and isDigit(value[3]) and isDigit(value[4]):
        return ok(parseFloat(value))
      err(IncorrectQValue)
    of '1':
      if (value[2] == '0') and (value[3] == '0') and (value[4] == '0'):
        return ok(1.0)
      err(IncorrectQValue)
    else:
      err(IncorrectQValue)
  else:
    err(IncorrectQValueLength)

proc toInt*(code: HttpCode): int =
  ## Returns ``code`` as integer value.
  case code
    of Http100: 100
    of Http101: 101
    of Http200: 200
    of Http201: 201
    of Http202: 202
    of Http203: 203
    of Http204: 204
    of Http205: 205
    of Http206: 206
    of Http300: 300
    of Http301: 301
    of Http302: 302
    of Http303: 303
    of Http304: 304
    of Http305: 305
    of Http307: 307
    of Http400: 400
    of Http401: 401
    of Http403: 403
    of Http404: 404
    of Http405: 405
    of Http406: 406
    of Http407: 407
    of Http408: 408
    of Http409: 409
    of Http410: 410
    of Http411: 411
    of Http412: 412
    of Http413: 413
    of Http414: 414
    of Http415: 415
    of Http416: 416
    of Http417: 417
    of Http418: 418
    of Http421: 421
    of Http422: 422
    of Http426: 426
    of Http428: 428
    of Http429: 429
    of Http431: 431
    of Http451: 451
    of Http500: 500
    of Http501: 501
    of Http502: 502
    of Http503: 503
    of Http504: 504
    of Http505: 505
