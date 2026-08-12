proc foo () :void=
  let tg = try: tag.call(commit, file) except err:
    log.warn("Skipping: {s}", .(@errorName(err)))
    continue
