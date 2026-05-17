fn find_first (n: i64) i64 {
  var current: i64 = 0;
  while (true) {
    if (current == n) {
      break;
    }
    current = current + 1;
  }
  return current;
}
