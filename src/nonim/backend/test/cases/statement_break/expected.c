#include <stdint.h>
static int64_t find_first (int64_t const n) {
  int64_t current = 0;
  while (true) {
    if (current == n) {
      break;
    }
    current = current + 1;
  }
  return current;
}
