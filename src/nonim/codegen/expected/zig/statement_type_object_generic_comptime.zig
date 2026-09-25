pub fn Thing (T :type, comptime ops :Ops(T)) type { return struct {
  data :T,
}; }
