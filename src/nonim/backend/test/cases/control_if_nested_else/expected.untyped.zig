pub fn thing (P :*const Data) void {
  if (P.first()) |tag| {
    if (P.second()) P.one(tag);
    } else P.two();
}
