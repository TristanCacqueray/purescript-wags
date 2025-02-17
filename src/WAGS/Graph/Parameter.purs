module WAGS.Graph.Parameter where

import Prelude hiding (apply)

import Control.Alt (class Alt)
import Control.Plus (class Plus)
import Data.Variant.Maybe (maybe, just, nothing, isNothing, Maybe)
import Data.Function (apply)
import Data.Generic.Rep (class Generic)
import Data.Newtype (class Newtype)
import Data.Show.Generic (genericShow)
import Data.Variant (Variant, inj)
import Record as R
import Type.Proxy (Proxy(..))

-- | A control-rate audio parameter as a newtype.
newtype AudioParameter_ a
  = AudioParameter (AudioParameter_' a)

type AudioParameter
  = AudioParameter_ Number

derive instance eqAudioParameter :: Eq a => Eq (AudioParameter_ a)
derive instance ordAudioParameter :: Ord a => Ord (AudioParameter_ a)

derive instance functorAudioParameter :: Functor AudioParameter_

instance altAudioParameter :: Alt AudioParameter_ where
  alt l@(AudioParameter { param: param0 }) r@(AudioParameter { param: param1 })
    | isNothing param1 = l
    | otherwise = if isNothing param0 then r else l

instance plusAudioParameter :: Plus AudioParameter_ where
  empty = AudioParameter (R.set (Proxy :: _ "param") nothing defaultParam)

instance applyAudioParameter :: Apply AudioParameter_ where
  apply = bop apply

instance applicativeAudioParameter :: Applicative AudioParameter_ where
  pure a = AudioParameter (R.set (Proxy :: _ "param") (just a) defaultParam)

instance bindAudioParameter :: Bind AudioParameter_ where
  bind (AudioParameter i@{ param }) f = maybe (AudioParameter (i { param = nothing })) (\a -> AudioParameter (R.set (Proxy :: _ "param") (just identity) i) <*> f a) param

instance monadAudioParameter :: Monad AudioParameter_

instance semigroupAudioParameter :: Semigroup a => Semigroup (AudioParameter_ a) where
  append = bop append

instance monoidAudioParameter :: Monoid a => Monoid (AudioParameter_ a) where
  mempty = pure mempty

derive instance newtypeAudioParameter :: Newtype (AudioParameter_ a) _

derive newtype instance showAudioParameter :: Show a => Show (AudioParameter_ a)

uop :: forall a b. (a -> b) -> AudioParameter_ a -> AudioParameter_ b
uop f (AudioParameter { param: param0, timeOffset: timeOffset0, transition: transition0 }) = AudioParameter { param: f <$> param0, timeOffset: timeOffset0, transition: transition0 }

bop :: forall a b c. (a -> b -> c) -> AudioParameter_ a -> AudioParameter_ b -> AudioParameter_ c
bop f (AudioParameter { param: param0, timeOffset: timeOffset0, transition: transition0 }) (AudioParameter { param: param1, timeOffset: timeOffset1, transition: transition1 }) = AudioParameter { param: f <$> param0 <*> param1, timeOffset: timeOffset0 + timeOffset1 / 2.0, transition: transition0 <> transition1 }

instance semiringAudioParameter :: Semiring a => Semiring (AudioParameter_ a) where
  zero = AudioParameter { param: just zero, timeOffset: 0.0, transition: _linearRamp }
  one = AudioParameter
    { param: just one
    , timeOffset: 0.0
    , transition: _linearRamp
    }
  add = bop add
  mul = bop mul

instance ringAudioParameter :: Ring a => Ring (AudioParameter_ a) where
  sub = bop sub

instance divisionRingAudioParameter :: DivisionRing a => DivisionRing (AudioParameter_ a) where
  recip = uop recip

instance commutativeRingAudioParameter :: CommutativeRing a => CommutativeRing (AudioParameter_ a)

instance euclideanRingAudioParameter :: EuclideanRing a => EuclideanRing (AudioParameter_ a) where
  degree (AudioParameter { param: param0 }) = maybe 0 degree param0
  div = bop div
  mod = bop mod

-- | A control-rate audio parameter.
-- |
-- | `param`: The parameter as a floating-point value _or_ an instruction to cancel all future parameters.
-- | `timeOffset`: How far ahead of the current playhead to set the parameter. This can be used in conjunction with the `headroom` parameter in `run` to execute precisely-timed events. For example, if the `headroom` is `20ms` and an attack should happen in `10ms`, use `timeOffset: 10.0` to make sure that the taret parameter happens exactly at the point of attack.
-- | `transition`: Transition between two points in time.

type AudioParameter_' a
  =
  { param :: Maybe a
  , timeOffset :: Number
  , transition :: AudioParameterTransition
  }

type AudioParameter'
  = AudioParameter_' Number

-- | A transition between two points in time.
-- | - `_noRamp` is a discrete step.
-- | - `_linearRamp` is linear interpolation between two values.
-- | - `ExponentialRamp` is exponential interpolation between two values.
-- | - `Immediately` erases the current value and replaces it with this one. Different than `_noRamp` in that it does not take into account scheduling and executes immediately. Useful for responsive instruments.
newtype AudioParameterTransition = AudioParameterTransition
  ( Variant
      ( noRamp :: Unit
      , linearRamp :: Unit
      , exponentialRamp :: Unit
      , immediately :: Unit
      )
  )

_noRamp :: AudioParameterTransition
_noRamp = AudioParameterTransition $ inj (Proxy :: _ "noRamp") unit

_linearRamp :: AudioParameterTransition
_linearRamp = AudioParameterTransition $ inj (Proxy :: _ "linearRamp") unit

_exponentialRamp :: AudioParameterTransition
_exponentialRamp = AudioParameterTransition $ inj (Proxy :: _ "exponentialRamp") unit

_immediately :: AudioParameterTransition
_immediately = AudioParameterTransition $ inj (Proxy :: _ "immediately") unit

derive instance newtypeAudioParameterTransition :: Newtype AudioParameterTransition _

derive instance eqAudioParameterTransition :: Eq AudioParameterTransition

instance ordAudioParameterTransition :: Ord AudioParameterTransition where
  compare i0 i1
    | i0 == _immediately = LT
    | i1 == _immediately = GT
    | otherwise = EQ

derive instance genericAudioParameterTransition :: Generic AudioParameterTransition _

instance showAudioParameterTransition :: Show AudioParameterTransition where
  show = genericShow

instance semigroupAudioParameterTransition :: Semigroup AudioParameterTransition where
  append i0 i1
    | i0 == _immediately || i1 == _immediately = _immediately
    | i0 == _exponentialRamp || i1 == _exponentialRamp = _exponentialRamp
    | i0 == _linearRamp || i1 == _linearRamp = _linearRamp
    | otherwise = _noRamp

ff :: forall a. Number -> AudioParameter_ a -> AudioParameter_ a
ff n (AudioParameter i) = AudioParameter (i { timeOffset = i.timeOffset + n })

modTime :: forall a. (Number -> Number) -> AudioParameter_ a -> AudioParameter_ a
modTime f (AudioParameter i) = AudioParameter (i { timeOffset = f i.timeOffset })

modParam :: forall a. (a -> a) -> AudioParameter_ a -> AudioParameter_ a
modParam f (AudioParameter i) = AudioParameter (i { param = f <$> i.param })

modRamp :: forall a. (AudioParameterTransition -> AudioParameterTransition) -> AudioParameter_ a -> AudioParameter_ a
modRamp f (AudioParameter i) = AudioParameter (i { transition = f i.transition })

noRamp :: forall a. AudioParameter_ a -> AudioParameter_ a
noRamp = modRamp (const _noRamp)

linearRamp :: forall a. AudioParameter_ a -> AudioParameter_ a
linearRamp = modRamp (const _linearRamp)

exponentialRamp :: forall a. AudioParameter_ a -> AudioParameter_ a
exponentialRamp = modRamp (const _exponentialRamp)

immediately :: forall a. AudioParameter_ a -> AudioParameter_ a
immediately = modRamp (const _immediately)

-- | A default audio parameter.
-- |
-- | defaultParam = { param: 0.0, timeOffset: 0.0, transition: _linearRamp }
defaultParam :: AudioParameter'
defaultParam = { param: just 0.0, timeOffset: 0.0, transition: _linearRamp }

class MM a b | a -> b where
  mm :: a -> b

instance maybeMM :: MM (Maybe a) (Maybe a) where
  mm = identity
else instance justMM :: MM a (Maybe a) where
  mm = pure
