pub fn fallback (a :?int, b :int) int {
  return a orelse b;
}
