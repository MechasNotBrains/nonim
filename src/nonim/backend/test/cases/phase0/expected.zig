const max: isize = 10;
var count: isize = 0;
const step: isize = 1;
fn increment (value: isize, amount: isize) isize {
  return value + amount;
}
fn accumulate (limit: isize) isize {
  var total: isize = 0;
  var current: isize = 0;
  while (current < limit) {
    total = increment(total, step);
    current = current + 1;
    if (current == 5) {
      _ = increment(current, 0);
      continue;
    }
    if (100 < total) {
      break;
    }
  }
  return total;
}
fn run () isize {
  const output: isize = accumulate(max);
  _ = count;
  return output;
}
