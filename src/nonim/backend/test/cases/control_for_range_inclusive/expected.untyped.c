#include <stddef.h>
int sum (int const count) {
  int result = 0;
  for (size_t id = 0; id <= count; ++id) {
    result += id;
  }
  return result;
}
