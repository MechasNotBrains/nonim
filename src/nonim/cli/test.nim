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

describe "nonim.cli | Backend Parsing":
  it "must parse every backend from its name", proc() =
    for backend in Backend: Backend.parse($backend).eq backend

  it "must return the fallback for an unknown backend name", proc() =
    Backend.parse("unknown", Backend.minc).eq Backend.minc

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

describe "nonim.cli | System":
  it "must default to an empty system", proc() =
    let options = options_parse(@["c", "input.zm"])
    options.system.os.eq ""
    options.system.cpu.eq ""
    options.system.abi.eq ""

  it "must parse the os option", proc() =
    let options = options_parse(@["--os:windows", "c", "input.zm"])
    options.system.os.eq "windows"

  it "must parse the cpu option", proc() =
    let options = options_parse(@["--cpu:aarch64", "c", "input.zm"])
    options.system.cpu.eq "aarch64"

  it "must parse the abi option", proc() =
    let options = options_parse(@["--abi:musl", "c", "input.zm"])
    options.system.abi.eq "musl"

  it "must parse the target option into cpu, os and abi", proc() =
    let options = options_parse(@["--target:aarch64-windows-gnu", "c", "input.zm"])
    options.system.cpu.eq "aarch64"
    options.system.os.eq "windows"
    options.system.abi.eq "gnu"

  it "must keep input and output positional when system options are given", proc() =
    let options = options_parse(@["c", "--os:linux", "--cpu:x86_64", "--abi:gnu", "src/game.zm", "bin/game"])
    options.input.eq "src/game.zm"
    options.output.eq "bin/game"

describe "nonim.cli | Extra Files":
  it "must default to no extra files", proc() =
    let options = options_parse(@["c", "input.zm"])
    options.files.c.len.eq 0
    options.files.c_dir.len.eq 0
    options.files.Include.len.eq 0

  it "must parse every cfile option", proc() =
    let options = options_parse(@["--cfile:a.c", "--cfile:b.c", "c", "input.zm"])
    options.files.c.eq @["a.c", "b.c"]

  it "must parse every cdir option", proc() =
    let options = options_parse(@["--cdir:src/c", "--cdir:lib/c", "c", "input.zm"])
    options.files.c_dir.eq @["src/c", "lib/c"]

  it "must parse every include option", proc() =
    let options = options_parse(@["--include:./bin/.lib/cvk/src", "--include:./bin/.lib", "c", "input.zm"])
    options.files.Include.eq @["./bin/.lib/cvk/src", "./bin/.lib"]

  it "must default to no linked libraries", proc() =
    let options = options_parse(@["c", "input.zm"])
    options.link.len.eq 0

  it "must parse every link option", proc() =
    let options = options_parse(@["--link:c", "--link:glfw", "--link:vulkan", "c", "input.zm"])
    options.link.eq @["c", "glfw", "vulkan"]

  it "must keep input and output positional when extra files are given", proc() =
    let options = options_parse(@["c", "--cfile:a.c", "--include:./bin/.lib", "src/game.zm", "bin/game"])
    options.input.eq "src/game.zm"
    options.output.eq "bin/game"
