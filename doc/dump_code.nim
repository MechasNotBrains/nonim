#:______________________________________________________________________________
#  kua  |  Copyright (C) Ivan Mar (sOkam!)  |  LicenseRef-All-Rights-Reserved  :
#:______________________________________________________________________________
const Kua  = @This().Type
const game = @This()
const Game = @This().Type
# @deps std
import @std
# @deps Game
const jera = block @struct:
  from @jera import cstring
  from @jera import Game
  from @jera import Jera as Engine


#______________________________________
# @section Object Fields
#____________________________
type Type = object
  title      :jera.cstring= "Kua.race | Debug"
  arena      :std.heap.ArenaAllocator
  callbacks  :jera.Game= .()
  # Create/Destroy
  destroy    {.alias: game_destroy  .}:proc
  create     {.alias: game_create   .}:proc


#______________________________________
# @section Create/Destroy
#____________________________
proc game_destroy (G :ptr Game) :void=
  defer: G.arena.deinit()
#__________________
proc game_create () : !Game=
  var result :Game= (arena: std.heap.ArenaAllocator.init(std.heap.page_allocator),)
  result.callbacks = (
    update         : (
      start        : update.start,
      fixed        : update.fixed,
      variable     : update.variable,
      `end`        : update.end,
    ) #:: result.callbacks.update
  ) #:: result.callbacks
  return result


#______________________________________
# @section Game Update
#____________________________
const update = block @struct:
  #______________________________________
  # @section Process
  #____________________________
  proc fixed (J :var ptr jera.Engine; G :jera.Game.Data) : !void= discard (J,G)
  proc variable (J :var ptr jera.Engine; G :jera.Game.Data) : !void=
    discard G
    # Move the camera
    J.ren.mess.tech.cam.update(&J.inp)

  #______________________________________
  # @section Start/End variable
  #____________________________
  proc start (J :var ptr jera.Engine; G :jera.Game.Data) : !void= discard (J,G)
  proc end (J :var ptr jera.Engine; G :jera.Game.Data) : !void=
    discard G
    if J.inp.key.active( .escape): J.sys.set_close(true)
    if J.inp.mouse.active( .left): J.sys.set_close(true)


