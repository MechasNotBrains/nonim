// Every C syntax construct that nonim targets.
// A feature MUST appear here before it can be implemented.

// [x] Variable: const (from let)
static int const answer = 42;

// [x] Variable: mutable (from var)
static int counter = 0;

// [x] Variable: exported (no static)
int const exported_answer = 42;

// [x] Procedure: forward declaration
static int add (int const x, int const y);

// [x] Procedure: with body
static int add (int const x, int const y) {
  return x + y;
}

// [x] Procedure: exported (no static)
int visible (int const x) {
  return x;
}

// [x] Expression: function call
static int main () {
  return add(1, 2);
}

// [x] Statement: discard
static void noop (int const x) {
  (void)(x / 2);
}

// [x] Literal: bool
static bool check_bool (bool const x) {
  if (x) {
    return true;
  }
  return false;
}

// [x] Variable: multiple bindings
static int64_t const a = 0;
static int64_t const b = 0;

// [x] Expression: assignment
static void increment (int64_t* x) {
  *x = *x + 1;
}

// [x] Control flow: if/else
static int64_t abs_val (int64_t const x) {
  if (x < 0) {
    return -x;
  } else {
    return x;
  }
}

// [x] Control flow: while
static void countdown (int64_t const n) {
  int64_t current = n;
  while (current > 0) {
    current = current - 1;
  }
}

// [x] Expression: indexed
static int64_t get_element (int64_t const arr[10], int64_t const idx) {
  return arr[idx];
}

// [x] Type: struct (from object)
typedef struct {
  float x;
  float y;
} Vec2;

// [ ] Type: enum
typedef enum {
  north,
  south,
  east,
  west,
} Direction;

// [ ] Type: alias
typedef int Integer;

// [ ] Include (from import)
#include <stdlib.h>
