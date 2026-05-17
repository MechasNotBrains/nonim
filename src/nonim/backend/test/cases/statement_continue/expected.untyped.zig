fn skip_negatives (n: int) void {
  var current: int = 0;
  while (current < n) {
    current = current + 1;
    if (current < 0) {
      continue;
    }
    _ = current;
  }
}
