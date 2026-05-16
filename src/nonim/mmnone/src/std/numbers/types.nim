#:__________________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________
type int  *{.magic: Int     .}
type uint *{.magic: UInt    .}
type i8   *{.magic: Int8    .}
type i16  *{.magic: Int16   .}
type i32  *{.magic: Int32   .}
type i64  *{.magic: Int64   .}
type u8   *{.magic: UInt8   .}
type u16  *{.magic: UInt16  .}
type u32  *{.magic: UInt32  .}
type u64  *{.magic: UInt64  .}
type f32  *{.magic: Float32 .}
type f64  *{.magic: Float   .}
type bool *{.magic: Bool    .} = enum false = 0, true = 1

type Ordinal *[T]{.magic: Ordinal.}

type SomeSigned       * =  int|i8|i16|i32|i64
type SomeUnsigned     * = uint|u8|u16|u32|u64
type SomeInteger      * = SomeSigned|SomeUnsigned
type SomeFloat        * = f32|f64
type SomeNumber       * = SomeInteger|SomeFloat
type SomeOrdinal      * = SomeSigned | bool | enum | SomeUnsigned

