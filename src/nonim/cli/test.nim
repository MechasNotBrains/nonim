#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for CLI option parsing.
#_______________________________________________________________|
# @deps tests
import minitest
# @deps nonim
import ../cli


describe "nonim.cli | Defaults":
  it "must default to cleanc backend", proc() =
    let options = options_parse(@["cc", "input.nim"])
    options.backend.eq Backend.cleanc

  it "must default to codegen command", proc() =
    let options = options_parse(@["cc", "input.nim"])
    options.command.eq Command.codegen

describe "nonim.cli | Commands":
  it "must parse c as compile command", proc() =
    let options = options_parse(@["c", "input.nim"])
    options.command.eq Command.compile

  it "must parse cc as codegen command", proc() =
    let options = options_parse(@["cc", "input.nim"])
    options.command.eq Command.codegen

  it "must parse r as run command", proc() =
    let options = options_parse(@["r", "input.nim"])
    options.command.eq Command.run

describe "nonim.cli | Backend Selection":
  it "must select minc backend when specified", proc() =
    let options = options_parse(@["--backend:minc", "cc", "input.nim"])
    options.backend.eq Backend.minc

  it "must select cleanc backend when specified", proc() =
    let options = options_parse(@["--backend:cleanc", "cc", "input.nim"])
    options.backend.eq Backend.cleanc

describe "nonim.cli | Input/Output":
  it "must parse input path", proc() =
    let options = options_parse(@["cc", "src/main.nim"])
    options.input.eq "src/main.nim"

  it "must parse explicit output path", proc() =
    let options = options_parse(@["cc", "src/main.nim", "bin/main"])
    options.output.eq "bin/main"

  it "must derive output from input when omitted", proc() =
    let options = options_parse(@["cc", "src/main.nim"])
    options.output.eq "src/main"

describe "nonim.cli | Flags":
  it "must parse verbose short flag", proc() =
    let options = options_parse(@["-v", "cc", "input.nim"])
    options.verbose.eq true

  it "must parse quiet long flag", proc() =
    let options = options_parse(@["--quiet", "cc", "input.nim"])
    options.quiet.eq true
