{ name = "purescript-wags"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "arraybuffer-types"
  , "arrays"
  , "behaviors"
  , "control"
  , "convertable-options"
  , "datetime"
  , "effect"
  , "either"
  , "event"
  , "everythings-better-with-variants"
  , "foldable-traversable"
  , "foreign"
  , "foreign-object"
  , "free"
  , "indexed-monad"
  , "integers"
  , "js-timers"
  , "lazy"
  , "lists"
  , "math"
  , "maybe"
  , "newtype"
  , "ordered-collections"
  , "prelude"
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
  , "variant"
  , "web-events"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
