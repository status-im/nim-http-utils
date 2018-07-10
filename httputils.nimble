packageName   = "httputils"
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "HTTP request/response helpers & parsing procedures"
license       = "Apache License 2.0"
skipDirs      = @["tests", "Nim"]

### Dependencies
requires "nim >= 0.17.3"

task test, "run tests":
  setCommand "c", "tests/tvectors.nim"
