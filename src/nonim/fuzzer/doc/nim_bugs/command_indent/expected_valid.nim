# Corrected version of the renderer output:
# First argument on the same line as the command name.

proc bar() =
  someProcedureWithAVeryLongNameThatForcesWrapping aVeryLongIdentifierNameThatWillForceTheRendererToWrapToTheNextLine,
      anotherVeryLongIdentifierThatPushesEvenFurtherPastTheLineLimit
