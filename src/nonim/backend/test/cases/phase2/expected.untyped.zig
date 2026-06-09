const std = @import("std");
pub const Target = std.Target;
pub fn classify (value :int) int {
  switch (value) {
    0 => {
      return 0;
    },
    1, 2 => {
      return 1;
    },
    else => {
      return 2;
    },
  }
}
pub fn process (x :int, y :int) int {
  var total :int= 0;
  const area :int= (x * y);
  total += classify(area);
  step: {
    var temp :int= area;
    temp += 1;
    total += temp;
  }
  {
    total += 1;
  }
  if (total > 100) {
    total = 100;
  } else if (total < 0) {
    total = 0;
  }
  return total;
}
pub fn run () int {
  const cfg = Target{.width= 10, .height= 20};
  return process(cfg.width, cfg.height);
}
