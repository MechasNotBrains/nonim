pub fn foo (callback: *const FnType) !void {
  callback.on_start.?(callback, callback.data);
}
