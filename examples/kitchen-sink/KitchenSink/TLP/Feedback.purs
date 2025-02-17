module WAGS.Example.KitchenSink.TLP.Feedback where

import Prelude

import Control.Applicative.Indexed (ipure)
import Control.Monad.Indexed.Qualified as Ix
import Data.Either (Either(..))
import Math ((%))
import Type.Proxy (Proxy(..))
import WAGS.Change (ichange)
import WAGS.Connect (iconnect)
import WAGS.Control.Functions (ibranch, icont)
import WAGS.Create (icreate)
import WAGS.Destroy (idestroy)
import WAGS.Disconnect (idisconnect)
import WAGS.Example.KitchenSink.TLP.LoopBuf (doLoopBuf)
import WAGS.Example.KitchenSink.TLP.LoopSig (StepSig)
import WAGS.Example.KitchenSink.Timing (pieceTime, timing)
import WAGS.Example.KitchenSink.Types.Empty (cursorGain)
import WAGS.Example.KitchenSink.Types.Feedback (FeedbackGraph, deltaKsFeedback)
import WAGS.Example.KitchenSink.Types.LoopBuf (ksLoopBufCreate)
import WAGS.Run (SceneI(..))

doFeedback :: forall proof. StepSig FeedbackGraph proof
doFeedback =
  ibranch \(SceneI { time, world })lsig ->
    if time % pieceTime < timing.ksFeedback.end then
      Right (deltaKsFeedback world time $> lsig)
    else
      Left
        $ icont doLoopBuf Ix.do
            let
              cursorDmix = Proxy :: _ "dmix"

              cursorDelay = Proxy :: _ "delay"

              cursorBuf = Proxy :: _ "buf"

              cursorHighpass = Proxy :: _ "highpass"
            idisconnect { source: cursorDmix, dest: cursorHighpass }
            idisconnect { source: cursorHighpass, dest: cursorDelay }
            idisconnect { source: cursorDelay, dest: cursorDmix }
            idisconnect { source: cursorBuf, dest: cursorDmix }
            idisconnect { source: cursorDmix, dest: cursorGain }
            idestroy cursorBuf
            idestroy cursorDmix
            idestroy cursorDelay
            idestroy cursorHighpass
            icreate (ksLoopBufCreate world)
            iconnect { source: Proxy :: _ "loopBuf", dest: cursorGain }
            ichange { mix: 1.0 }
            ipure lsig
