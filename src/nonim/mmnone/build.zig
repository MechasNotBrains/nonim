//:_________________________________________________________
//  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
//:_________________________________________________________
const confy = @import("./bin/.cache/confy/lib/confy/src/confy.zig");

const flags_mmnone = &.{
  "--mm:none",
  "-d:gcnone",

  "-d:useMalloc",
  "-d:noSignalHandler",

  "--checks:off",
  "--assertions:off",
  "--exceptions:goto",
  "--panics:on",

  "--stackTrace:off",
  "--lineTrace:off",

  "--threads:off",
  "--tlsEmulation:off",  // Implicit by threads:off

  "--deepcopy:off",  // Implicit by mm:none

  "--passC:\"-fsanitize=address,undefined\"",
  "--passL:\"-fsanitize=address,undefined\"",
  "--passL:\"-lasan\"",
  "--passL:\"-lubsan\"",
  "--passL:\"-L/usr/lib/gcc/x86_64-linux-gnu/13\"",

  // Override system lib
  "--lib:src/std",
  "--passC:\"-I./src/std\"",

  // Custom Compiler Hacks
  "-d:nimCstringLiterals",
};

pub fn main () !void {
  broken: {
    var string_concat = try confy.Program("samples/broken/strings_concat.nim", .{
      .cfg   = confy.Config.strict(),
      .flags = flags_mmnone,
    }); try string_concat.build(); try string_concat.run();

    break: broken;
  }

  var hello = try confy.Program("samples/hello/src/hello.nim", .{
    .cfg   = confy.Config.strict(),
    .flags = flags_mmnone,
  });
  try hello.build(); try hello.run();
}

