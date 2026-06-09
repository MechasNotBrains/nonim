pub var Foo = t.describe("foo tests");
test Foo {
  Foo.begin();
  defer Foo.end();
  try it("foo test", struct { fn f () !void {
  const x = 1;
}}.f);
}
pub var Bar = t.describe("bar tests");
test Bar {
  Bar.begin();
  defer Bar.end();
  try it("bar test", struct { fn f () !void {
  const y = 2;
}}.f);
}
