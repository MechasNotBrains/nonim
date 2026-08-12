pub fn foo () void {
  const tg = tag.call(commit, file) catch |err| {
    log.warn("Skipping: {s}", .{@errorName(err)});
    continue;
  };
}
