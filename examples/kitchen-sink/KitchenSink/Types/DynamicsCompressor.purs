module WAGS.Example.KitchenSink.Types.DynamicsCompressor where

import Prelude

import Data.Tuple.Nested (type (/\))
import Math ((%))
import WAGS.Change (ichange)
import WAGS.Create.Optionals (CDynamicsCompressor, CPlayBuf, compressor, playBuf)
import WAGS.Example.KitchenSink.TLP.LoopSig (IxWAGSig', World)
import WAGS.Example.KitchenSink.Timing (timing, pieceTime)
import WAGS.Example.KitchenSink.Types.Empty (TopWith)
import WAGS.Graph.AudioUnit (TDynamicsCompressor, TPlayBuf)

type DynamicsCompressorGraph
  = TopWith { compressor :: Unit }
  ( compressor :: TDynamicsCompressor /\ { buf :: Unit }
  , buf :: TPlayBuf /\ {}
  )

ksDynamicsCompressorCreate :: World -> { compressor :: CDynamicsCompressor { buf :: CPlayBuf } }
ksDynamicsCompressorCreate { buffers: { "my-buffer": myBuffer } } = { compressor: compressor {} { buf: playBuf myBuffer } }

deltaKsDynamicsCompressor :: forall proof. World -> Number -> IxWAGSig' DynamicsCompressorGraph DynamicsCompressorGraph proof Unit
deltaKsDynamicsCompressor { buffers: { "my-buffer": myBuffer, shruti } } =
  (_ % pieceTime)
    >>> (_ - timing.ksDynamicsCompressor.begin)
    >>> (max 0.0)
    >>> \time ->
      let
        switchW = time % 4.0 < 2.0

        changes =
          { mix: if time > (timing.ksDynamicsCompressor.dur - 1.0) then 0.0 else 1.0
          , compressor:
              { threshold: if time > (dur / 2.0) then -50.0 else -40.0
              , knee: if time > (dur / 3.0) then 20.0 else 40.0
              , ratio: if time > (dur / 4.0) then 2.0 else 5.0
              , attack: if time > (dur / 5.0) then 0.003 else 0.005
              , release: if time > (dur / 6.0) then 0.25 else 0.5
              }
          , buf: if switchW then myBuffer else shruti
          }
      in
        ichange changes
  where
  dur = timing.ksDynamicsCompressor.dur
