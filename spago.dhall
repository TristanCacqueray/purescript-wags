{ name = "purescript-wags"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "arraybuffer-types"
  , "behaviors"
  , "control"
  , "convertable-options"
  , "datetime"
  , "effect"
  , "either"
  , "event"
  , "foldable-traversable"
  , "foreign"
  , "foreign-object"
  , "free"
  , "heterogeneous"
  , "indexed-monad"
  , "integers"
  , "js-timers"
  , "lists"
  , "math"
  , "maybe"
  , "newtype"
  , "nullable"
  , "ordered-collections"
  , "prelude"
  , "profunctor-lenses"
  , "psci-support"
  , "record"
  , "refs"
  , "safe-coerce"
  , "simple-json"
  , "sized-vectors"
  , "tuples"
  , "typelevel"
  , "typelevel-peano"
  , "typelevel-prelude"
  , "unsafe-coerce"
  , "unsafe-reference"
  , "web-events"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
