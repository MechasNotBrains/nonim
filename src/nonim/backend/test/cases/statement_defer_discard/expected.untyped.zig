pub fn cleanup (f :i64) i64 {
  defer _ = close(f);
  return process(f);
}
