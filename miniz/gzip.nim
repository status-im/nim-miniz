# nim-miniz
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import
  stew/results,
  ./miniz_api

proc gzip*[T: byte|char](N: type, source: openArray[T]): Result[N, string] =
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

  var r = mz.deflateInit2(
    MZ_DEFAULT_LEVEL,
    MZ_DEFLATED,
    MZ_RAW_DEFLATE,
    MZ_DEFAULT_MEM_LEVEL,
    MZ_DEFAULT_STRATEGY)

  if r != MZ_OK:
    return err($r)

  let maxSize = mz.deflateBound(source.len.culong).int
  when N is string:
    type CC = char
    var res = newString(maxSize + 18)
  elif N is seq[byte]:
    type CC = byte
    var res = newSeq[byte](maxSize + 18)
  else:
    {.fatal: "unsupported output type".}

  res[0] = 0x1F.CC
  res[1] = 0x8B.CC
  res[2] = 8.CC
  res[3] = 0.CC
  res[4] = 0.CC
  res[5] = 0.CC
  res[6] = 0.CC
  res[7] = 0.CC
  res[8] = 0.CC
  res[9] = 0xFF.CC

  mz.next_out = cast[ptr cuchar](res[10].addr)
  mz.avail_out = (res.len - 10).cuint
  r = mz.deflate(MZ_FINISH)

  if r != MZ_STREAM_END:
    return err($r)

  let
    size  = mz.total_out.int
    crc   = mz_crc32(source)
    ssize = source.len

  res[size + 10] = CC(         crc and 0xFF)
  res[size + 11] = CC((crc shr 8)  and 0xFF)
  res[size + 12] = CC((crc shr 16) and 0xFF)
  res[size + 13] = CC((crc shr 24) and 0xFF)
  res[size + 14] = CC(         ssize and 0xFF)
  res[size + 15] = CC((ssize shr 8)  and 0xFF)
  res[size + 16] = CC((ssize shr 16) and 0xFF)
  res[size + 17] = CC((ssize shr 24) and 0xFF)

  res.setLen(mz.total_out.int + 18)
  r = mz.deflateEnd()
  if r != MZ_OK:
    return err($r)

  ok(res)

proc ungzip*[T: byte|char](N: type, data: openArray[T]): Result[N, string] =
  var mz = MzStream(
    next_in: if data.len == 0:
               nil
             else:
               cast[ptr cuchar](data[10].unsafeAddr),
    avail_in: data.len.cuint - 18
  )

  const windowBits = MZ_RAW_DEFLATE
  var r = mz.inflateInit2(windowBits)

  if r != MZ_OK:
    return err($r)

  var res: seq[byte]
  var buf: array[0xFFFF, byte]

  while true:
    mz.next_out  = cast[ptr cuchar](buf[0].addr)
    mz.avail_out = buf.len.cuint
    r = mz.inflate(MZ_SYNC_FLUSH)
    let outSize = buf.len - mz.avail_out.int
    res.add toOpenArray(buf, 0, outSize-1)
    if r == MZ_STREAM_END:
      break
    elif r == MZ_OK:
      # need more input or more output available
      if mz.avail_in > 0 or mz.avail_out == 0:
        continue
      else:
        break
    else:
      return err("decompression error: " & $r)

  r = mz.inflateEnd()
  if r != MZ_OK:
    return err($r)

  when N is string:
    ok(cast[string](res))
  elif N is seq[byte]:
    ok(res)
  else:
    {.fatal: "unsupported output type".}
