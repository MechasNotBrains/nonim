#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## nimgen: Entry Point
#______________________|
when isMainModule:
  from std/os import commandLineParams
  from ./fuzzer/cli import nil
  cli.run(os.commandLineParams())
