#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## MinC Standalone: Entry Point
#_______________________________|
when isMainModule:
  import ./cli
  import ./backend/minc
  let options = cli.options_parse(default_backend = cli.Backend.minc)
  minc.run(options)

