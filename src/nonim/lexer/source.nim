#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Source types for the lexer: Position, Location, Code.
#_______________________________________________________________|


type Position * = uint64
type Code * = string

const Invalid * :Position= high(Position)

type Location * = object
  start * :Position= Invalid
  `end` * :Position= Invalid

func valid *(location :Location) :bool= location.start != Invalid and location.`end` != Invalid
func invalid *(location :Location) :bool= not location.valid()
func adjacent *(location_b :Location; location_a :Location) :bool= location_b.start == location_a.`end` + 1
func max *(location :Location) :Position= location.`end` + 1
func eq *(location_a :Location; location_b :Location) :bool= location_a.start == location_b.start and location_a.`end` == location_b.`end`
func len *(location :Location) :Position= location.max() - location.start
func `from` *(location :Location; source :Code) :string=
  if location.valid(): source[location.start ..< location.max()]
  else: ""
func add *(location_a :var Location; location_b :Location) =
  if location_a.eq(location_b): return
  assert location_b.adjacent(location_a), "Tried to add a location to another, but the locations are not adjacent."
  location_a.`end` = location_b.`end`
