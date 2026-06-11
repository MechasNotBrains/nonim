proc main () :void=
  {.emit: "const thing :[*]u8= @ptrCast(data);".}
  return thing[0]
