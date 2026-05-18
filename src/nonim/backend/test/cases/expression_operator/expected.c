#include <stdint.h>
static void operators (int64_t const x, int64_t const y) {
  (void)(x / y);
  (void)(x % y);
  (void)(x << y);
  (void)(x >> y);
  (void)(x ^ y);
}
