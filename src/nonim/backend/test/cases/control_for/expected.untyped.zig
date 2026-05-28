pub fn sum (vals: []const int) int {
  var result: int = 0;
  for (vals) |val| {
    result += val;
  }
  return result;
}
