# nim-miniz
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

mode = ScriptMode.Verbose

packageName   = "miniz"
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "miniz wrapper in nim"
license       = "Apache License 2.0"
skipDirs      = @["tests"]

requires "nim >= 1.2.0"

# Helper functions
proc test(env, path: string) =
  # Compilation language is controlled by TEST_LANG
  var lang = "c"
  if existsEnv("TEST_LANG"):
    lang = getEnv("TEST_LANG")

  exec "nim " & lang & " " & env &
    " -r --hints:off --skipParentCfg " & path

task test, "Run all tests":
  test "-d:debug", "tests/test_all"
  test "-d:release", "tests/test_all"
  test "--threads:on -d:release", "tests/test_all"
