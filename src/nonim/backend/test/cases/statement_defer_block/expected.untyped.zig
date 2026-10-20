pub fn cleanup (f :i64) i64 {
  defer {
    close(f);
    _ = free(f);
  }
  return process(f);
}
