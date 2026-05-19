## Import: minz — Include Design Notes
Zig has no `#include` or preprocessor directives.
The minz backend handles Nim `include` statements differently from minc.


### 1. Recursive include (no extension): `include module` → contents inlined
**Status: implemented.**
Identical to minc.
The preprocessor (`backend/preprocess.nim`) is shared between minc and minz.
It resolves extensionless `include` lines by recursively inlining the referenced source files (`.nim`, `.cm`, `.zm`)
before the Nim parser sees the code. Called by `backend/minz.nim` before `Untyped.compile`.


### 2. Global include (`@`) and local include (with extension): NOT native to Zig
**Status: not implemented.**

Zig has no native equivalent of C's `#include <...>` or `#include "..."`.
The `@` prefix and extension-based include forms (`include @stdint.h`, `include path/to/file.h`)
do not map to any Zig construct.

**Plan:**
These cases will fall through to the parser as `statement.passthrough`.
The converter will not produce `StatementImport` nodes for them.
Instead, they will be emitted as raw text.
A **post-process pass** will then operate on the resulting Zig output code string
to resolve these includes by copy/pasting the contents of the referenced `.zig` files directly into the output.

This is fundamentally different from the minc approach:
- **minc**: The converter distinguishes `@`/extension includes and the C codegen emits `#include <>`/`#include ""` directives.
            The C compiler handles the actual file resolution.
- **minz**: Since Zig has no include directives, nonim must resolve the files itself and physically inline the contents into the output string.
            This happens as a post-processing step AFTER codegen, not before parsing.

The post-process pass:
1. Runs after `codegen/zig.nim` produces the output string
2. Scans the output for passthrough lines that look like include directives
3. Resolves the referenced `.zig` files relative to the output location
4. Replaces the passthrough lines with the file contents
5. May need recursion (included files can themselves contain includes)

