# Invalid code produced by the renderer:
# Command arguments wrap to an indentation the parser rejects.

proc bar() =
  someProcedureWithAVeryLongNameThatForcesWrapping
      aVeryLongIdentifierNameThatWillForceTheRendererToWrapToTheNextLine,
      anotherVeryLongIdentifierThatPushesEvenFurtherPastTheLineLimit
