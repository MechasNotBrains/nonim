// Every Zig syntax construct that nonim targets.
// A feature MUST appear here before it can be implemented.

// [x] Variable: const (from let)
const answer: i64 = 42;

// [x] Variable: var (from var)
var counter: i64 = 0;

// [x] Variable: exported (pub)
pub const exported_answer: i64 = 42;

// [x] Procedure: forward declaration
fn add(x: i64, y: i64) i64;

// [x] Procedure: with body
fn add(x: i64, y: i64) i64 {
    return x + y;
}

// [x] Procedure: exported (pub)
pub fn visible(x: i64) i64 {
    return x;
}

// [x] Expression: function call
fn main() i64 {
    return add(1, 2);
}

// [x] Statement: discard
fn noop (x: i64) void {
    _ = x / 2;
}

// [x] Literal: bool
fn check_bool (x: bool) bool {
  if (x) {
    return true;
  }
  return false;
}

// [x] Literal: nil
fn nothing () void {
  _ = null;
}

// [x] Literal: float
const pi: f64 = 3.14159;

// [x] Literal: string
const greeting: [:0]const u8 = "hello";

// [x] Literal: char
const letter: u8 = 'a';

// [x] Variable: multiple bindings
const a: isize = 0;
const b: isize = 0;

// [x] Expression: assignment
fn increment (x: *isize) void {
    x.* = x.* + 1;
}

// [x] Control flow: if/else
fn abs_val (x: isize) isize {
  if (x < 0) {
    return -x;
  } else {
    return x;
  }
}

// [x] Control flow: while
fn countdown (n: isize) void {
  var current: isize = n;
  while (current > 0) {
    current = current - 1;
  }
}

// [x] Expression: indexed
fn get_element (arr: [10]isize, idx: isize) isize {
  return arr[idx];
}

// [x] Type: struct (from object)
const Vec2 = struct {
  x: f32,
  y: f32,
};

// [ ] Type: enum
const Direction = enum {
    north,
    south,
    east,
    west,
};

// [ ] Type: alias
const Integer = i64;

// [ ] Import (from import)
const std = @import("std");
