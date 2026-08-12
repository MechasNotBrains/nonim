fn find_first (n :isize) isize {
  var current :isize= 0;
  while (true) {
    if (current == n) break;
    current = current + 1;
}
  return current;
}
