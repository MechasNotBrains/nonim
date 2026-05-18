#include <stdint.h>
static int64_t abs_val (int64_t const x) {
  if (x < 0) {
    return -x;
  } else {
    return x;
  }
}
