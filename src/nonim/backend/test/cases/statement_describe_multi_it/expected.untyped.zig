pub var Thing = t.describe("thing tests");
test Thing {
  Thing.begin();
  defer Thing.end();
  try it("first test", struct { fn f () !void {
  const x = 1;
}}.f);
  try it("second test", struct { fn f () !void {
  const y = 2;
}}.f);
}
