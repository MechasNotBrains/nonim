# Corrected version of the renderer output:
# Block wrapping provides correct indentation context for try/except.

proc foo() =
  echo ((block:
    try:
      42
    except:
      0
  ))
