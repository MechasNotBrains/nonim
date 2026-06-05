@namespace vertex {.private.}:
  const array {.align: @alignOf(u32).}= @embedFile("./mess.vert.spv")[]  # array of u8s, length is however big the file is
  const code :array[_, u32]= @ptrCast(array.addr)

