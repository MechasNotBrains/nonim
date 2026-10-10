{.define: debug_mode -> 1.}
when debug_mode:
  let level :int= 2
else:
  let level :int= 0
when defined(linux):
  let platform :int= 1
  when debug_mode:
    let verbose :int= 1
when defined("__linux__"):
  {.define: unix.}
when defined(DEBUG):
  {.define: build_debug -> true.}
else:
  {.define: build_debug -> false.}
proc trace () :int=
  when debug_mode:
    let depth :int= 3
    return depth
  return 0
