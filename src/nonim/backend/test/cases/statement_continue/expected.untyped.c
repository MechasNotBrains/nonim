static void skip_negatives (int const n) {
  int current = 0;
  while (current < n) {
    current = current + 1;
    if (current < 0) {
      continue;
    }
    (void)(current);
  }
}
