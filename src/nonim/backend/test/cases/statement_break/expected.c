static int find_first (int const n) {
  int current = 0;
  while (true) {
    if (current == n) {
      break;
    }
    current = current + 1;
  }
  return current;
}
