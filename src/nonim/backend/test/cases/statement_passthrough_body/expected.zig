pub fn main () void {
  const thing :[*]u8= @ptrCast(data);
  return thing[0];
}
