pub fn unwrap (a :?int) int {
  const value = a orelse return 0;
  return value;
}
