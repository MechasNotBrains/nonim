## Import: minz — Include Design Notes
Zig has no `#include` or preprocessor directives.
The minz backend handles Nim `include` statements differently from minc.


### 1. Recursive include (no extension): `include module` → contents inlined
**Status: implemented.**
Identical to minc.
The preprocessor (`backend/preprocess.nim`) is shared between minc and minz.
It resolves extensionless `include` lines by recursively inlining the referenced source files (`.nim`, `.cm`, `.zm`)
before the Nim parser sees the code. Called by `backend/minz.nim` before `Untyped.compile`.


### 2. Global include (`@`) and local include (`.zig` extension): NOT native to Zig
**Status: implemented** (`backend/postprocess.nim`, run from `backend/minz.nim` after codegen).

Zig has no native equivalent of C's `#include <...>` or `#include "..."`.
Users must reference `.zig` files explicitly, e.g. `include @stdint.zig` or `include path/to/file.zig`.
C-style `.h` paths are a minc concern only.

These cases are emitted as passthrough `include …` lines by the converter,
then resolved and inlined by the post-process pass (`backend/includes.nim` shared loop).

- **minc**: `@`/extension includes become `#include` directives; the C compiler resolves paths.
- **minz**: nonim resolves `.zig` files relative to the input file and inlines their contents into the output.
