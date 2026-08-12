pub fn foo (P :*const Type) void {
  P.value = store(P) catch |err| return;
}
