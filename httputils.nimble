packageName   = "httputils"
version       = "0.2.0"
author        = "Status Research & Development GmbH"
description   = "HTTP request/response helpers & parsing procedures"
license       = "Apache License 2.0"
skipDirs      = @["tests", "Nim"]

### Dependencies
requires "nim >= 0.17.3"

task test, "run tests":
  exec "nim c -r -d:useSysAssert -d:useGcAssert tests/tvectors"
  exec "nim c -r tests/tvectors"
  exec "nim c -r -d:release tests/tvectors"
