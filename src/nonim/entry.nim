#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
import ./cli
import ./backend/cleanc
import ./backend/zig
import ./backend/minc
import ./backend/minz
import ./backend/minatf

proc run *() :void=
  let options = cli.options_parse()
  case options.backend
  of Backend.cleanc : cleanc.run(options)
  of Backend.zig    : zig.run(options)
  of Backend.minc   : minc.run(options)
  of Backend.minz   : minz.run(options)
  of Backend.minatf : minatf.run(options)
