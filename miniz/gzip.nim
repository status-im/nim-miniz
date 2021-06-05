# nim-miniz
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import
  ./miniz_api

proc gzip*[T: byte|char](N: type, source: openArray[T]): N =
  # all these cast[ptr cuchar] is need because
  # clang++ will complaints about incompatible
  # pointer types
  var mz = MzStream(
    next_in: if source.len == 0:
               nil
             else:
               cast[ptr cuchar](source[0].unsafeAddr),
    avail_in: source.len.cuint
  )

  assert(mz.deflateInit2(
    MZ_DEFAULT_LEVEL,
    MZ_DEFLATED,
    MZ_RAW_DEFLATE,
    1,
    MZ_DEFAULT_STRATEGY) == MZ_OK
  )

  let maxSize = mz.deflateBound(source.len.culong).int
  when N is string:
    type CC = char
    result = newString(maxSize + 18)
  elif N is seq[byte]:
    type CC = byte
    result = newSeq[byte](maxSize + 18)
  else:
    {.fatal: "unsupported output type".}

  result[0] = 0x1F.CC
  result[1] = 0x8B.CC
  result[2] = 8.CC
  result[3] = 0.CC
  result[4] = 0.CC
  result[5] = 0.CC
  result[6] = 0.CC
  result[7] = 0.CC
  result[8] = 0.CC
  result[9] = 0xFF.CC

  mz.next_out = cast[ptr cuchar](result[10].addr)
  mz.avail_out = (result.len - 10).cuint
  assert(mz.deflate(MZ_FINISH) == MZ_STREAM_END)

  let
    size  = mz.total_out.int
    crc   = mz_crc32(source)
    ssize = source.len

  result[size + 10] = CC(         crc and 0xFF)
  result[size + 11] = CC((crc shr 8)  and 0xFF)
  result[size + 12] = CC((crc shr 16) and 0xFF)
  result[size + 13] = CC((crc shr 24) and 0xFF)
  result[size + 14] = CC(         ssize and 0xFF)
  result[size + 15] = CC((ssize shr 8)  and 0xFF)
  result[size + 16] = CC((ssize shr 16) and 0xFF)
  result[size + 17] = CC((ssize shr 24) and 0xFF)

  result.setLen(mz.total_out.int + 18)
  assert(mz.deflateEnd() == MZ_OK)

proc ungzip*[T: byte|char](N: type, data: openArray[T]): N =
  var mz = MzStream(
    next_in: if data.len == 0:
               nil
             else:
               cast[ptr cuchar](data[10].unsafeAddr),
    avail_in: data.len.cuint - 18
  )

  const windowBits = MZ_RAW_DEFLATE
  doAssert(mz.inflateInit2(windowBits) == MZ_OK)
  var res: seq[byte]
  var buf: array[0xFFFF, byte]

  while true:
    mz.next_out  = cast[ptr cuchar](buf[0].addr)
    mz.avail_out = buf.len.cuint
    let r = mz.inflate(MZ_SYNC_FLUSH)
    let outSize = buf.len - mz.avail_out.int
    res.add toOpenArray(buf, 0, outSize-1)
    if r == MZ_STREAM_END:
      break
    elif r == MZ_OK:
      continue
    else:
      doAssert(false, "decompression error")

  doAssert(mz.inflateEnd() == MZ_OK)

  when N is string:
    cast[string](res)
  elif N is seq[byte]:
    res
  else:
    {.fatal: "unsupported output type".}
