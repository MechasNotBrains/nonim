pub fn thing (T :type) void {
  var count :int= 0;
  inline for (@typeInfo(T).@"struct".fields) |field| {
    _ = field;
}
  _ = count;
}
