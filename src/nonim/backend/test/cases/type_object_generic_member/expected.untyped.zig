pub fn Holder (T :type) type { return struct {
  data :T,
  pub fn get (S :*const Holder(T)) T {
    return S.data;
  }
}; }
