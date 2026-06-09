pub fn foo (x :int) int {
  switch (x) {
    1, 2 => {
      return 10;
    },
    3 => {
      return 30;
    },
    else => {
      return 0;
    },
  }
}
