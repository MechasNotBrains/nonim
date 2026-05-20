import @std
const Target = std.Target

proc classify (value :int) :int=
  case value
  of 0: return 0
  of 1, 2: return 1
  else: return 2

proc process (x :int; y :int) :int=
  var total :int= 0
  let area :int= (x * y)
  total += classify(area)
  block step:
    var temp :int= area
    temp += 1
    total += temp
  block _:
    total += 1
  if total > 100:
    total = 100
  elif total < 0:
    total = 0
  return total

proc run () :int=
  let cfg = Target(width: 10, height: 20)
  return process(cfg.width, cfg.height)
