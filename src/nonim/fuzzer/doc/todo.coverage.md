# Nim Syntax Coverage

## Expressions: 29/31 (2 blocked by renderer bugs)
- Blocked: nkDo (`do_missing_space`), nkStmtListExpr (`stmtlistexpr_nosemicolon`)

## Literals: 8/8

## Statements dispatched: 8/27
- Done: var, let, const, proc, call, command, assignment, discard
- Missing: func, method, converter, macro, template, iterator, if, when, case, for, while, block, try, raise, return, break, continue, yield, defer

## Module statements: 4/6
- Done: import, import-except, from, include
- Missing: export, export-except

## Other statements: 1/5
- Done: comment
- Missing: asm, pragma (stmt), using, bind/mixin

## Type definitions: 0/12
- Missing: type section, object, enum, tuple, distinct, ref, ptr, proc type, iterator type, variant object, when-in-object, concept

## Structural: 0/4
- Missing: generics, var tuple, pragma block, static stmt

## Total: 50/93 (54%)
