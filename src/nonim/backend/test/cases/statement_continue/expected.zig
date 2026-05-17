fn skip_negatives (n: i64) void {
  var current: i64 = 0;
  while (current < n) {
    current = current + 1;
    if (current < 0) {
      continue;
    }
    _ = current;
  }
}
