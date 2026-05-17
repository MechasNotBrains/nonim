#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Grammar types: Grammar, Rule, Pattern, Element.
#_______________________________________________________________|


type ElementKind * = enum
  ekValue
  ekRule

type Element * = object
  kind  * :ElementKind
  value * :string

type Pattern * = seq[Element]

type Rule * = object
  name        * :string
  category    * :string
  pattern     * :Pattern
  node_type   * :string
  constructor * :string
  comment     * :string

type Grammar * = object
  rules * :seq[Rule]
