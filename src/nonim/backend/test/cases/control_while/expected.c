#include <stdint.h>
static void countdown (int64_t const n) {
  int64_t current = n;
  while (0 < current) {
    current = current - 1;
  }
}
