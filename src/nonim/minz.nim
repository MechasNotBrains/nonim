#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## MinZ Standalone: Entry Point
#_______________________________|
when isMainModule:
  import ./cli
  import ./backend/minz
  let options = cli.options_parse()
  minz.run(options)
