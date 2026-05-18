#include <stdint.h>
static void skip_negatives (int64_t const n) {
  int64_t current = 0;
  while (current < n) {
    current = current + 1;
    if (current < 0) {
      continue;
    }
    (void)(current);
  }
}
