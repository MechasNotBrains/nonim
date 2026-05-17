#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/source.nim
#_______________________________________________________________|
import minitest
import ./source


describe "nonim.lexer | Location.valid":
  it "must return true when both start and end are set", proc()=
    let location = Location(start: 0, `end`: 5)
    location.valid().eq true

  it "must return false when start is Invalid", proc()=
    let location = Location(`end`: 5)
    location.valid().eq false

  it "must return false when end is Invalid", proc()=
    let location = Location(start: 0)
    location.valid().eq false

  it "must return false for default Location", proc()=
    let location = Location()
    location.valid().eq false


describe "nonim.lexer | Location.adjacent":
  it "must return true when B starts right after A ends", proc()=
    let location_a = Location(start: 0, `end`: 4)
    let location_b = Location(start: 5, `end`: 9)
    location_b.adjacent(location_a).eq true

  it "must return false when B does not start right after A", proc()=
    let location_a = Location(start: 0, `end`: 4)
    let location_b = Location(start: 7, `end`: 9)
    location_b.adjacent(location_a).eq false


describe "nonim.lexer | Location.len":
  it "must return the length of the location", proc()=
    let location = Location(start: 0, `end`: 4)
    location.len().eq 5'u64

  it "must return 1 for a single-char location", proc()=
    let location = Location(start: 3, `end`: 3)
    location.len().eq 1'u64


describe "nonim.lexer | Location.from":
  it "must extract substring from source", proc()=
    let location = Location(start: 0, `end`: 4)
    location.`from`("hello world").eq "hello"

  it "must return empty for invalid location", proc()=
    let location = Location()
    location.`from`("hello").eq ""


describe "nonim.lexer | Location.add":
  it "must merge two adjacent locations", proc()=
    var location_a = Location(start: 0, `end`: 2)
    let location_b = Location(start: 3, `end`: 5)
    location_a.add(location_b)
    location_a.`end`.eq 5'u64

  it "must be a no-op when locations are equal", proc()=
    var location_a = Location(start: 0, `end`: 4)
    let location_b = Location(start: 0, `end`: 4)
    location_a.add(location_b)
    location_a.`end`.eq 4'u64
