#:__________________________________________________________________
#  Jeraᛃ  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________
##! @fileoverview Cable Connector to all Jera modules
#_____________________________________________________|
# @deps mstd
from ./zig/mdk.zig import mstd.cstring
# @deps Jera
const jera * = @This()
const Jera * = jera.Engine.type
from ./zig/core.zig import type as Engine
from ./zig/game.zig import type as Game


#______________________________________
# @section Debug Example: Entry Point
#____________________________
import std
proc main *() : !void=
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator); defer: arena.deinit()
  var J = try : Jera.create(arena.allocator(), (
    system    : (
      window  : (
        title : "Jeraᛃ Engine | Debug Example" ))))
  J.start()

