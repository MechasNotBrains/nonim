#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## CLI tests for the minc command.
#_______________________________________________________________|
import minitest
import ../cli


describe "nonim.cli.minc | Defaults":
  it "must select minc backend", proc() =
    let options = options_parse(@["--backend:minc", "cc", "input.nim"])
    options.backend.eq Backend.minc
