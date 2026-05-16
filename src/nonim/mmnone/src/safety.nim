# {.push raises: [].}  # compiler error if any proc can raise — forces you to handle it
# {.push checks: off.} # disables runtime checks (overflow, bounds, nil) for a section
# {.noInit.}           # prevents zero-initialization of variables
# {.global.}           # for statics that need to survive across calls without heap
