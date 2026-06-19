pub fn Container (T :type) type {
  return struct {
    items :seq(T),
    count :u32,
};
}
