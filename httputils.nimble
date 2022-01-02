packageName   = "httputils"
version       = "0.3.0"
author        = "Status Research & Development GmbH"
description   = "HTTP request/response helpers & parsing procedures"
license       = "Apache License 2.0"
skipDirs      = @["tests", "Nim"]

### Dependencies
requires "nim >= 0.17.3",
         "stew",
         "unittest2"

task test, "run tests":
  let envNimflags = getEnv("NIMFLAGS")
  exec "nim c -r " & envNimflags & " -d:useSysAssert -d:useGcAssert --styleCheck:usages --styleCheck:error tests/tvectors"
  exec "nim c -r " & envNimflags & " tests/tvectors"
  exec "nim c -r " & envNimflags & " -d:release --threads:on tests/tvectors"
