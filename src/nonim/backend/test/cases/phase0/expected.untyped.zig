pub const max: isize = 10;
pub var count: isize = 0;
pub const step: isize = 1;
pub fn increment (value: isize, amount: isize) isize {
  return value + amount;
}
pub fn accumulate (limit: isize) isize {
  var total: isize = 0;
  var current: isize = 0;
  while (current < limit) {
    total = increment(total, step);
    current = current + 1;
    if (current == 5) {
      _ = increment(current, 0);
      continue;
    }
    if (total > 100) {
      break;
    }
  }
  return total;
}
pub fn run () isize {
  const output: isize = accumulate(max);
  _ = count;
  return output;
}
