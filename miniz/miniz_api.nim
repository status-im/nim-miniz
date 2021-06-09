# nim-miniz
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import strutils
from os import quoteShell, DirSep, AltSep

const
  minizPath = currentSourcePath.rsplit({DirSep, AltSep}, 1)[0]

{.passC: "-I" & quoteShell(minizPath).}
{.passC: "-D_LARGEFILE64_SOURCE=1".}
{.compile: minizPath & "/" & "miniz.c".}

type
  MzError* {.size: sizeof(cint).} = enum
    MZ_PARAM_ERROR   = -10000
    MZ_VERSION_ERROR = -6
    MZ_BUF_ERROR     = -5
    MZ_MEM_ERROR     = -4
    MZ_DATA_ERROR    = -3
    MZ_STREAM_ERROR  = -2
    MZ_ERRNO         = -1
    MZ_OK            = 0
    MZ_STREAM_END    = 1
    MZ_NEED_DICT     = 2

  MzLevel* {.size: sizeof(cint).} = enum
    MZ_DEFAULT_COMPRESSION  = -1
    MZ_NO_COMPRESSION       = 0
    MZ_BEST_SPEED           = 1
    MZ_LEVEL_2              = 2
    MZ_LEVEL_3              = 3
    MZ_LEVEL_4              = 4
    MZ_LEVEL_5              = 5
    MZ_LEVEL_6              = 6
    MZ_LEVEL_7              = 7
    MZ_LEVEL_8              = 8
    MZ_BEST_COMPRESSION     = 9
    MZ_UBER_COMPRESSION     = 10

  MzMemLevel* {.size: sizeof(cint).} = enum
    MZ_MEM_1 = 1
    MZ_MEM_2 = 2
    MZ_MEM_3 = 3
    MZ_MEM_4 = 4
    MZ_MEM_5 = 5
    MZ_MEM_6 = 6
    MZ_MEM_7 = 7
    MZ_MEM_8 = 8
    MZ_MEM_9 = 9

  MzMethod* {.size: sizeof(cint).} = enum
    MZ_DEFLATED = 8

  MzWindowBits* {.size: sizeof(cint).} = enum
    MZ_RAW_DEFLATE         = -15
    MZ_RAW_WINDOW_BITS_14  = -14
    MZ_RAW_WINDOW_BITS_13  = -13
    MZ_RAW_WINDOW_BITS_12  = -12
    MZ_RAW_WINDOW_BITS_11  = -11
    MZ_RAW_WINDOW_BITS_10  = -10
    MZ_RAW_WINDOW_BITS_9   = -9
    MZ_RAW_WINDOW_BITS_8   = -8

    MZ_WINDOW_BITS_8       = 8
    MZ_WINDOW_BITS_9       = 9
    MZ_WINDOW_BITS_10      = 10
    MZ_WINDOW_BITS_11      = 11
    MZ_WINDOW_BITS_12      = 12
    MZ_WINDOW_BITS_13      = 13
    MZ_WINDOW_BITS_14      = 14
    MZ_WINDOW_BITS_15      = 15

  MzStrategy* {.size: sizeof(cint).} = enum
    MZ_DEFAULT_STRATEGY = 0
    MZ_FILTERED         = 1
    MZ_HUFFMAN_ONLY     = 2
    MZ_RLE              = 3
    MZ_FIXED            = 4

  MzFlush* {.size: sizeof(cint).} = enum
    MZ_NO_FLUSH      = 0
    MZ_PARTIAL_FLUSH = 1
    MZ_SYNC_FLUSH    = 2
    MZ_FULL_FLUSH    = 3
    MZ_FINISH        = 4
    MZ_BLOCK         = 5

  MzStream* {.importc: "mz_stream", header: "miniz.h".} = object
    next_in*   : ptr cuchar  # pointer to next byte to read
    avail_in*  : cuint    # number of bytes available at next_in
    total_in   : culong   # total number of bytes consumed so far

    next_out*  : ptr cuchar # pointer to next byte to write
    avail_out* : cuint    # number of bytes that can be written to next_out
    total_out* : culong   # total number of bytes produced so far

const
  MZ_DEFAULT_MEM_LEVEL*   = MZ_MEM_8
  MZ_DEFAULT_WINDOW_BITS* = MZ_WINDOW_BITS_15
  MZ_DEFAULT_LEVEL*       = MZ_LEVEL_6

proc mz_version*(): ptr char {.cdecl, importc: "mz_version",
              header: "miniz.h".}

proc deflateInit*(mz: var MzStream, level: MzLevel): MzError {.cdecl,
                  importc: "mz_deflateInit", header: "miniz.h".}

proc deflateInit2*(mz: var MzStream, level: MzLevel, meth: MzMethod,
                   windowBits: MzWindowBits, memLevel: MzMemLevel,
                   strategy: MzStrategy): MzError {.cdecl,
                   importc: "mz_deflateInit2", header: "miniz.h".}

proc deflate*(mz: var MzStream, flush: MzFlush): MzError {.cdecl,
              importc: "mz_deflate", header: "miniz.h".}

proc deflateBound*(mz: var MzStream, sourceLen: culong): culong {.cdecl,
                   importc: "mz_deflateBound", header: "miniz.h".}

proc deflateReset*(mz: var MzStream): MzError {.cdecl,
                   importc: "mz_deflateReset", header: "miniz.h".}

proc deflateEnd*(mz: var MzStream): MzError {.cdecl,
                 importc: "mz_deflateEnd", header: "miniz.h".}

proc inflateInit*(mz: var MzStream): MzError {.cdecl,
                 importc: "mz_inflateInit", header: "miniz.h".}

proc inflateInit2*(mz: var MzStream,
                   windowBits: MzWindowBits): MzError {.cdecl,
                   importc: "mz_inflateInit2", header: "miniz.h".}

proc inflateReset*(mz: var MzStream): MzError {.cdecl,
                   importc: "mz_inflateReset", header: "miniz.h".}

proc inflate*(mz: var MzStream, flush: MzFlush): MzError {.cdecl,
              importc: "mz_inflate", header: "miniz.h".}

proc inflateEnd*(mz: var MzStream): MzError {.cdecl,
                 importc: "mz_inflateEnd", header: "miniz.h".}

proc mz_error*(err: MzError): ptr char {.cdecl,
            importc: "mz_error", header: "miniz.h".}

const
  MZ_CRC32_INIT* = 0.culong

proc mz_crc32*(crc: culong, buf: ptr cuchar,
               bufLen: csize_t): culong {.cdecl,
               importc: "mz_crc32", header: "miniz.h".}

func mz_crc32*[T: byte|char](input: openArray[T]): culong =
  let dataPtr = if input.len == 0:
                  nil
                else:
                  cast[ptr cuchar](input[0].unsafeAddr)
  mz_crc32(MZ_CRC32_INIT,
    dataPtr,
    input.len.csize_t
  ).culong
