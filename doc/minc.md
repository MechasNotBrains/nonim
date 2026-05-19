## Import: minc — Include Design Notes
The minc backend uses Nim's `include` statement with three distinct syntax forms that map to different C behaviors.
The Nim parser produces `nkIncludeStmt` for all three;
the converter distinguishes them by analyzing the child node structure.

Reference implementation:
`/home/arch/gd/other/mech/csearch/references/minc/src/minc/prep.nim` (preprocessor)
and `.../minc/tools.nim` (module path parsing).

### 1. Global include: `include @stdint.h` → `#include <stdint.h>`
The `@` prefix signals a global/system include.
The Nim parser produces `nkIncludeStmt > nkDotExpr(nkPrefix("@", "stdint"), "h")`.
The converter's `include_is_global` detects the `@` prefix by walking the tree,
strips it via `include_path`, and sets `global: some(true)` on the `StatementImport`.
The C codegen wraps the path in `<>`.


### 2. Local include with extension: `include path/to/file.h` → `#include "path/to/file.h"`
A path with a file extension (`.h`, `.c`) but no `@` prefix is a local/relative include.
The Nim parser produces nested `nkInfix("/", ...)` with a `nkDotExpr("file", "h")` leaf.
The converter's `include_has_ext` detects the `nkDotExpr`,
`include_path` reconstructs the full dotted path, and `global` is set to `some(false)`.
The C codegen wraps the path in `""`.


### 3. Recursive include (no extension): `include module` → contents inlined
A path with NO file extension and NO `@` prefix is a minc source file include.
This is NOT an `#include`.
It is a **preprocessor step** that recursively reads the referenced `.nim` file
and inlines its contents into the source BEFORE the Nim parser sees it.
This happens in `backend/preprocess.nim`, called by `backend/minc.nim` before `Untyped.compile`.

Implementation (`backend/preprocess.nim`):
- `processIncludes(source, inputPath)` is the entry point — takes raw source and the input file path
- Splits source into lines; lines matching `include <path>` where path has no extension and no `@` are recursive includes
- The referenced file is resolved relative to the current file's directory with `.nim` extension appended
- The file's contents are recursively processed for further includes
- A `HashSet[string]` of already-included absolute paths prevents infinite recursion
- The final flattened source string is passed to the Nim parser — include lines are consumed and never reach the converter

