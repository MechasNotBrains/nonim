
{.emit: "const thing :[*]u8= @ptrCast(data);".}  # FIX: Remove this! We need a way to represent pointers to many in minz/minim

proc main () :void=
  {.emit: "const other :[*]u8= @ptrCast(data);".}  # FIX: Remove this! We need a way to represent pointers to many in minz/minim
  return thing[0] + other[1]

