#:________________________________________________________
#  mmath  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:________________________________________________________
const float * = @This()
const This = @This();
# @deps std
import @std
# @deps mmath
const mmath = block @struct:
  const float = This


#______________________________________
# @section Constants
#____________________________
from ./base import Epsilon


#______________________________________
# @section Value Checks
#____________________________
proc zero *(N :anytype) :bool {.inline.}= return @abs(N) < mmath.float.Epsilon
proc eq   *(N :anytype, val :anytype) :bool {.inline.}= return @abs(N-val) < mmath.float.Epsilon


const trunc * = mmath.float.truncate
#____________________________
## @descr Removes all decimals from floating point number {@arg val} after {@arg N} decimals.
## @warning
##  The given {@arg T} float type MUST be able to hold all decimals of {@arg val},
##  or there will be imprecision errors.
##  These errors can break determinism, and make the value be rounded up.
##  eg: (f32, 0.100099999999, 4) will become `0.1001`, and not `0.1000` as it would be expected.
proc truncate *(T :typedesc, val :T, N :usize) :T {.inline.}=
  let factor     = @as(T, @floatFromInt(std.math.pow(@TypeOf(N), 10, N)))
  let scaled     = @abs(val) * factor
  let correction = @max(scaled, 1.0) * std.math.floatEps(T) * 4
  return std.math.copysign(@trunc(scaled + correction) / factor, val)

