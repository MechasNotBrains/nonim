pub fn roots (a :anytype) [2]@TypeOf(a) {
  const result :[2]@TypeOf(a)= .{a, a};
  return result;
}
