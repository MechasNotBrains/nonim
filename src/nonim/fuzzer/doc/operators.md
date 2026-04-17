# Nim Operator Syntax Rules

Reference for operator syntax constraints by position. Based on the
[Nim manual (Operators section)](https://nim-lang.org/docs/manual.html#lexical-analysis-operators)
and extended with position-specific rules discovered through parser testing.

## Operator Characters

Nim operators are built from the following character sets:

**ASCII:**
```
=  +  -  *  /  <  >  @  $  ~  &  %  |  !  ?  ^  .  :  \
```

**Unicode** (selected from U+2200..U+22FF):
```
∙  ∘  ×  ★  ⊗  ⊘  ⊙  ⊛  ⊠  ⊡  ∩  ∧  ⊓        (multiplicative precedence)
±  ⊕  ⊖  ⊞  ⊟  ∪  ∨  ⊔                          (additive precedence)
```

**Keyword operators:**
```
and  or  not  xor  shl  shr  div  mod  in  notin  is  isnot  of  as  from
```

Multi-character operators are formed by concatenating ASCII or Unicode
operator characters.

## Reserved Tokens (from the manual)

The manual states that `.`, `=`, `:`, `::` are not available as general
operators — they are used for other notational purposes. Additionally,
`*:` is treated as two tokens `*` and `:` (to support `var v*: T`), and
`not` is always a unary operator.

## Position-specific Rules

The following rules are not fully enumerated in the manual but follow from
Nim's lexer and parser behavior.

### Infix (binary): `a op b`

All operator characters, multi-character combinations, and keyword operators
are valid in infix position, **except**:

| Invalid | Reason |
|---------|--------|
| `=`     | Reserved token: lexed as assignment |
| `.`     | Reserved token: lexed as dot expression |
| `:`     | Reserved token: lexed as block/type separator |
| `::`    | Reserved token: lexed as a single grammar token |
| `*:`    | Lexed as two tokens `*` and `:` |
| `not`   | Unary-only keyword: `a not b` is parsed as `a(not b)` |

Operators ending in `=` (e.g. `+=`, `-=`, `:=`) are valid — only bare `=`
is intercepted. Operators ending in `:` (e.g. `+:`, `-:`, `.:`) are valid —
only `*:` and `::` are intercepted.

### Prefix (unary): `op a`

All operator characters, multi-character combinations, and keyword operators
are valid in prefix position, **except**:

| Invalid | Reason |
|---------|--------|
| `=`                | Reserved token: lexed as assignment |
| `:`                | Reserved token: lexed as block/type separator |
| `.`                | Reserved token: lexed as dot expression start |
| `..`               | Lexed as range token |
| `*:`               | Lexed as two tokens `*` and `:` |
| all keywords except `not` | Parser rejects keyword operators in unary position |

Multi-character operators starting with `.` are valid when the remaining
characters disambiguate from `.` and `..` (e.g. `...`, `.+`, `.<` all
parse correctly). These are "dot-like operators" per the manual.

### Postfix: `a op`

Postfix position is only valid for the `*` export marker in declarations
(`proc foo*`, `var x*`). This is a grammar-level construct — `*` is not
treated as a general postfix expression operator.

In expression context, the parser reads `a*` as identifier `a` followed by
prefix `*` applied to the next token.

### Keyword Operators by Position

| Keyword  | Prefix | Infix |
|----------|--------|-------|
| `not`    | yes    | no    |
| `and`    | no     | yes   |
| `or`     | no     | yes   |
| `xor`    | no     | yes   |
| `div`    | no     | yes   |
| `mod`    | no     | yes   |
| `shl`    | no     | yes   |
| `shr`    | no     | yes   |
| `in`     | no     | yes   |
| `notin`  | no     | yes   |
| `is`     | no     | yes   |
| `isnot`  | no     | yes   |
| `of`     | no     | yes   |
| `as`     | no     | yes   |
| `from`   | no     | yes   |
