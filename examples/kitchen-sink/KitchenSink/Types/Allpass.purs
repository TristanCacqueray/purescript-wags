module WAGS.Example.KitchenSink.Types.Allpass where

import Prelude
import Data.Tuple.Nested (type (/\))
import Math ((%))
import Record as Record
import Type.Proxy (Proxy(..))
import WAGS.Change (ichange)
import WAGS.Create.Optionals (CAllpass, CPlayBuf, allpass, playBuf)
import WAGS.Example.KitchenSink.TLP.LoopSig (IxWAGSig')
import WAGS.Example.KitchenSink.Timing (timing, pieceTime)
import WAGS.Example.KitchenSink.Types.Empty (TopWith)
import WAGS.Graph.AudioUnit (OnOff(..), TAllpass, TPlayBuf)
import WAGS.Math (calcSlope)

type AllpassGraph
  = TopWith { allpass :: Unit }
      ( allpass :: TAllpass /\ { buf :: Unit }
      , buf :: TPlayBuf /\ {}
      )

ksAllpassCreate :: { allpass :: CAllpass { buf :: CPlayBuf "my-buffer"  } }
ksAllpassCreate = { allpass: allpass { freq: 300.0 } { buf: playBuf (Proxy :: _ "my-buffer") } }

deltaKsAllpass :: forall proof. Number -> IxWAGSig' AllpassGraph AllpassGraph proof Unit
deltaKsAllpass =
  (_ % pieceTime)
    >>> (_ - timing.ksAllpass.begin)
    >>> (max 0.0)
    >>> \time ->
        let
          switchOO = time % 2.0 < 1.0

          switchW = time % 4.0 < 2.0

          changes =
            { mix: if time > (timing.ksAllpass.dur - 1.0) then 0.0 else 1.0
            , allpass: calcSlope 0.0 300.0 timing.ksAllpass.dur 2000.0 time
            }

          onOff = if switchOO then On else Off
        in
          if switchW then
            ichange
              $ Record.union
                  changes
                  { buf: { onOff, buffer: Proxy :: _ "my-buffer" }
                  }
          else
            ichange
              $ Record.union
                  changes
                  { buf: { onOff, buffer: Proxy :: _ "shruti" }
                  }
