# Invalid code produced by the renderer:
# Parser rejects `except` at wrong indentation inside parens.

proc foo() =
  echo (try:
    42
  except:
    0
  )
