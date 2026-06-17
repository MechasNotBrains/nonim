pub fn clamp (value :int, limit :int) int {
  if (value > limit) {
    _ = value;
    return limit;
    } else return value;
}
