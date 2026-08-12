pub fn thing (T :type) void {
  _ = @typeInfo(T).@"struct".fields;
}
