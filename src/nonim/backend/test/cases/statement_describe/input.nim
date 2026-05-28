@describe Truncate, "mmath.float.truncate":
  @it "must truncate to 2 decimal places", proc(): !void=
    let result = mmath.float.truncate(f32, 3.14159, 2)
    try: t.eq(result, @as(f32, 3.14)
