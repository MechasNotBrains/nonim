pub var Truncate = t.describe("mmath.float.truncate");
test Truncate {
  Truncate.begin();
  defer Truncate.end();
  try it("must truncate to 2 decimal places", struct { fn f () !void {
  const result = mmath.float.truncate(f32, 3.14159, 2);
  try t.eq(result, @as(f32, 3.14));
}}.f);
}
