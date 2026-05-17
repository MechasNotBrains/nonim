fn skip_negatives (n: isize) void {
  var current: isize = 0;
  while (current < n) {
    current = current + 1;
    if (current < 0) {
      continue;
    }
    _ = current;
  }
}
