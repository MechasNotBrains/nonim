pub fn thing (P :*const Data) void {
  if (P.valid()) P.one() else if (P.stored()) |fallback| P.two(fallback) else P.three();
}
