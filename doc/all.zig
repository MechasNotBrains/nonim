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

// [ ] Procedure: exported (pub)
pub fn visible(x: i64) i64 {
    return x;
}

// [ ] Expression: function call
fn main() i64 {
    return add(1, 2);
}

// [ ] Expression: assignment
fn increment(x: *i64) void {
    x.* = x.* + 1;
}

// [ ] Control flow: if/else
fn abs_val(x: i64) i64 {
    if (x < 0) {
        return -x;
    } else {
        return x;
    }
}

// [ ] Control flow: while
fn countdown(n: i64) void {
    var current = n;
    while (current > 0) {
        current = current - 1;
    }
}

// [ ] Type: struct (from object)
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
