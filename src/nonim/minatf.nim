#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## MinZ Standalone: Entry Point
#_______________________________|
when isMainModule:
  import ./cli
  import ./backend/minatf
  let options = cli.options_parse(default_backend = cli.Backend.minatf)
  minatf.run(options)
