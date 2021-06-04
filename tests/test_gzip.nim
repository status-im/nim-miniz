# nim-miniz
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import
  std/[unittest, os],
  ../miniz/gzip
  
suite "gzip test suite":
  const 
    rawFolder = "tests" / "data"
  
  for path in walkDirRec(rawFolder):
    let parts = splitFile(path)
    test parts.name:
      let s = readFile(path)
      let str = string.gzip(s)
      let bytes = seq[byte].gzip(s)
      check bytes.len == str.len
      