#include <stdint.h>
static int64_t const max = 10;
static int64_t count = 0;
static int64_t const step = 1;
static int64_t increment (int64_t const value, int64_t const amount) {
  return value + amount;
}
static int64_t accumulate (int64_t const limit) {
  int64_t total = 0;
  int64_t current = 0;
  while (current < limit) {
    total = increment(total, step);
    current = current + 1;
    if (current == 5) {
      (void)(increment(current, 0));
      continue;
    }
    if (100 < total) {
      break;
    }
  }
  return total;
}
static int64_t run () {
  int64_t const output = accumulate(max);
  (void)(count);
  return output;
}
