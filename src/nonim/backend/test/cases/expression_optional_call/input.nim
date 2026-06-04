proc foo (callback :ptr FnType): !void=
  callback.on_start.?(callback, callback.data)
