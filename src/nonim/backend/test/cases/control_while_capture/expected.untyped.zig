pub fn process (pixels :Pixels) void {
  while (pixels.next()) |pixel| {
    _ = pixel;
  }
}
