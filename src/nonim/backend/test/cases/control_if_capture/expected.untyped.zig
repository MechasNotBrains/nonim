pub fn check (thing :?Thing) void {
  if (thing) |value| {
    _ = value;
  } else {
    _ = {};
  }
}
