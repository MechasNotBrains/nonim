static int const max = 10;
static int count = 0;
static int const step = 1;
static int increment (int const value, int const amount) {
  return value + amount;
}
static int accumulate (int const limit) {
  int total = 0;
  int current = 0;
  while (current < limit) {
    total = increment(total, step);
    current = current + 1;
    if (current == 5) {
      (void)(increment(current, 0));
      continue;
    }
    if (total > 100) {
      break;
    }
  }
  return total;
}
static int run () {
  int const output = accumulate(max);
  (void)(count);
  return output;
}
