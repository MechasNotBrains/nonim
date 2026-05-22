pub fn foo (x: int, y: int) int {
  switch (x) {
    1 => {
      switch (y) {
        10 => {
          return 100;
        },
        else => {
          return 0;
        },
      }
    },
    else => {
      return 0;
    },
  }
}
