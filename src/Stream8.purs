module Stream8 where

import Prelude

import Control.Applicative.Indexed (class IxApplicative, iapplySecond)
import Control.Apply.Indexed (class IxApply)
import Control.Bind.Indexed (class IxBind)
import Control.Lazy (fix)
import Control.Monad.Indexed (class IxMonad)
import Control.Monad.Indexed.Qualified as Ix
import Control.Monad.State (State, execState, get, gets, modify_, withState)
import Control.Monad.Writer (WriterT(..), runWriterT)
import Data.Functor.Indexed (class IxFunctor)
import Data.Generic.Rep (class Generic)
import Data.Identity (Identity(..))
import Data.Int.Bits (shl)
import Data.Map as M
import Data.Maybe (Maybe(..), isJust, maybe)
import Data.Monoid.Endo (Endo(..))
import Data.Set (Set)
import Data.Set as S
import Data.Show.Generic (genericShow)
import Data.Tuple (Tuple(..), fst, snd)
import Data.Tuple.Nested (type (/\), (/\))
import Data.Typelevel.Bool (class And, False, True)
import Prim.TypeError (class Warn, Above, Quote, Text)
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)

type D0 = (Bc O Bn)
type D1 = (Bc I Bn)
type D2 = (Bc O (Bc I Bn))
type D3 = (Bc I (Bc I Bn))
type D4 = (Bc O (Bc O (Bc I Bn)))
type D5 = (Bc I (Bc O (Bc I Bn)))
type D6 = (Bc O (Bc I (Bc I Bn)))
type D7 = (Bc I (Bc I (Bc I Bn)))

infixr 5 type Above as ^^

infixr 5 type NodeListCons as /:

infixr 5 type PtrListCons as +:

infixr 5 type NodeC as /->

data Bin

foreign import data I :: Bin

foreign import data O :: Bin

data BinL

foreign import data Bc :: Bin -> BinL -> BinL

foreign import data Bn :: BinL

type Ptr
  = BinL

data AudioUnitList

foreign import data AudioUnitCons :: AudioUnit -> AudioUnitList -> AudioUnitList

foreign import data AudioUnitNil :: AudioUnitList

data PtrList

foreign import data PtrListCons :: Ptr -> PtrList -> PtrList

foreign import data PtrListNil :: PtrList

data SkolemPair

foreign import data SkolemPairC :: Type -> Ptr -> SkolemPair

data SkolemList

foreign import data SkolemListCons :: SkolemPair -> SkolemList -> SkolemList

foreign import data SkolemListNil :: SkolemList

data EdgeProfile

-- non empty
foreign import data ManyEdges :: Ptr -> PtrList -> EdgeProfile

foreign import data SingleEdge :: Ptr -> EdgeProfile

foreign import data NoEdge :: EdgeProfile

data AudioUnit

foreign import data TSinOsc :: Ptr -> AudioUnit

foreign import data THighpass :: Ptr -> AudioUnit

foreign import data TGain :: Ptr -> AudioUnit

foreign import data TSpeaker :: Ptr -> AudioUnit

data Node

foreign import data NodeC :: AudioUnit -> EdgeProfile -> Node

data NodeList

foreign import data NodeListCons :: Node -> NodeList -> NodeList

foreign import data NodeListNil :: NodeList

data Graph

-- non empty
foreign import data GraphC :: Node -> NodeList -> Graph

foreign import data InitialGraph :: Graph

data Universe

-- currentIdx graph skolems accumulator
foreign import data UniverseC :: Ptr -> Graph -> SkolemList -> Type -> Universe

---------------------------
------------ util
cunit :: forall a. a -> Unit
cunit = const unit

class GetAccumulator (u :: Universe) (acc :: Type) | u -> acc

instance getAccumulator :: GetAccumulator (UniverseC ptr graph skolems acc) acc

class GetGraph (u :: Universe) (g :: Graph) | u -> g

instance getGraphUniverseC :: GetGraph (UniverseC ptr graph skolems acc) graph

class GetPointer (audioUnit :: AudioUnit) (ptr :: Ptr) | audioUnit -> ptr

instance getPointerSinOsc :: GetPointer (TSinOsc ptr) ptr

instance getPointerHighpass :: GetPointer (THighpass ptr) ptr

instance getPointerGain :: GetPointer (TGain ptr) ptr

instance getPointerSpeaker :: GetPointer (TSpeaker ptr) ptr

class BinToInt (i :: BinL) where
  toInt'' :: Int ->  Proxy i -> Int

instance toIntBn :: BinToInt Bn where
  toInt'' _ _ = 0

instance toIntBcO :: BinToInt r => BinToInt (Bc O r) where
  toInt'' x _ = toInt'' (x `shl` 1) (Proxy :: _ r)

instance toIntBcI :: BinToInt r => BinToInt (Bc I r) where
  toInt'' x _ = x + toInt'' (x `shl` 1) (Proxy :: _ r)

toInt' :: forall (i :: BinL). BinToInt i => Proxy i -> Int
toInt' = toInt'' 1

class BinSucc (i :: BinL) (o :: BinL) | i -> o

instance binSuccNull :: BinSucc Bn (Bc I Bn)

instance binSuccO :: BinSucc (Bc O r) (Bc I r)

instance binSuccI :: BinSucc r r' => BinSucc (Bc I r) (Bc O r')

class BinSub' (carrying :: Type) (l :: BinL) (r :: BinL) (o :: BinL) | carrying l r -> o

instance binSubDoneIF :: BinSub' False (Bc I r) Bn (Bc I r)

instance binSubDoneIT :: BinSub' True (Bc I r) Bn (Bc O r)

instance binSubDoneOF :: BinSub' False (Bc O r) Bn (Bc O r)

instance binSubDoneOT :: BinSub' True r Bn o => BinSub' True (Bc O r) Bn o

instance binSubNul1 :: BinSub' True Bn (Bc x y) Bn

instance binSubNul2 :: BinSub' True Bn Bn Bn

instance binSubNul3 :: BinSub' False Bn (Bc x y) Bn

instance binSubNul4 :: BinSub' False Bn Bn Bn

instance binSubIterFOO :: BinSub' False i o r => BinSub' False (Bc O i) (Bc O o) (Bc O r)

instance binSubIterFIO :: BinSub' False i o r => BinSub' False (Bc I i) (Bc O o) (Bc I r)

instance binSubIterFOI :: BinSub' True i o r => BinSub' False (Bc O i) (Bc I o) (Bc I r)

instance binSubIterFII :: BinSub' False i o r => BinSub' False (Bc I i) (Bc I o) (Bc O r)

----------
instance binSubIterTOO :: BinSub' False (Bc O i) (Bc I o) x => BinSub' True (Bc O i) (Bc O o) x

instance binSubIterTIO :: BinSub' False (Bc I i) (Bc I o) x => BinSub' True (Bc I i) (Bc O o) x

instance binSubIterTOI :: BinSub' True i o r => BinSub' True (Bc O i) (Bc I o) (Bc O r)

instance binSubIterTII :: BinSub' False (Bc O i) (Bc I o) x => BinSub' True (Bc I i) (Bc I o) x

class Beq (a :: Bin) (b :: Bin) (tf :: Type) | a b -> tf

instance beqOO :: Beq O O True

instance beqOI :: Beq O I False

instance beqIO :: Beq I O False

instance beqII :: Beq I I True

class BinEq (a :: BinL) (b :: BinL) (tf :: Type) | a b -> tf

instance binEq0 :: BinEq Bn Bn True

instance binEq1 :: BinEq Bn (Bc x y) False

instance binEq2 :: BinEq (Bc x y) Bn False

instance binEq3 :: (Beq a x tf, BinEq b y rest, And tf rest r) => BinEq (Bc a b) (Bc x y) r

class AllZerosToNull (i :: BinL) (o :: BinL) | i -> o

instance allZerosToNullBn :: AllZerosToNull Bn Bn

instance allZerosToNullBcI :: AllZerosToNull (Bc I o) (Bc I o)

instance allZerosToNullBcO :: AllZerosToNull o x => AllZerosToNull (Bc O o) x

class RemoveTrailingZeros (i :: BinL) (o :: BinL) | i -> o

instance removeTrailingZerosBn :: RemoveTrailingZeros Bn Bn

instance removeTrailingZerosI :: RemoveTrailingZeros r r' => RemoveTrailingZeros (Bc I r) (Bc I r')

instance removeTrailingZerosO ::
  ( AllZerosToNull r n
  , RemoveTrailingZeros r r'
  , BinEq n Bn tf
  , Gate tf Bn (Bc O r') x
  ) =>
  RemoveTrailingZeros (Bc O r) x

class BinSub (l :: BinL) (r :: BinL) (o :: BinL) | l r -> o

instance binSub :: (BinSub' False l r o', RemoveTrailingZeros o' o) => BinSub l r o

class Gate tf l r o | tf l r -> o

instance gateTrue :: Gate True l r l

instance gateFalse :: Gate False l r r

class GraphToNodeList (graph :: Graph) (nodeList :: NodeList) | graph -> nodeList, nodeList -> graph

instance graphToNodeList :: GraphToNodeList (GraphC node nodeList) (NodeListCons node nodeList)

instance graphToNodeListIG :: GraphToNodeList InitialGraph NodeListNil

class GetAudioUnit (node :: Node) (au :: AudioUnit) | node -> au

instance getAudioUnitNodeC :: GetAudioUnit (NodeC au ep) au

class LookupSkolem' (accumulator :: PtrList) (skolem :: Type) (skolemList :: SkolemList) (ptr :: PtrList) | accumulator skolem skolemList -> ptr

instance lookupSkolemNil :: LookupSkolem' accumulator ptr SkolemListNil accumulator

instance lookupSkolemCons ::
  ( TypeEqualTF skolem candidate tf
  , Gate tf (PtrListCons ptr PtrListNil) PtrListNil toComp
  , PtrListKeepSingleton toComp accumulator acc
  , LookupSkolem' acc skolem tail o
  ) =>
  LookupSkolem' accumulator skolem (SkolemListCons (SkolemPairC candidate ptr) tail) o

class LookupSkolem (skolem :: Type) (skolemList :: SkolemList) (ptr :: Ptr) | skolem skolemList -> ptr

instance lookupSkolem :: (LookupSkolem' PtrListNil skolem skolemList (PtrListCons ptr PtrListNil)) => LookupSkolem skolem skolemList ptr

class TypeEqualTF (a :: Type) (b :: Type) (c :: Type) | a b -> c

instance typeEqualTFT :: TypeEqualTF a a True
else instance typeEqualTFF :: TypeEqualTF a b False

instance skolemNotYetPresentNil :: SkolemNotYetPresent skolem SkolemListNil

instance skolemNotYetPresentCons ::
  ( TypeEqualTF skolem candidate False
  , SkolemNotYetPresentOrDiscardable skolem tail
  ) =>
  SkolemNotYetPresent skolem (SkolemListCons (SkolemPairC candidate ptr) tail)

class SkolemNotYetPresent (skolem :: Type) (skolemList :: SkolemList)

class SkolemNotYetPresentOrDiscardable (skolem :: Type) (skolemList :: SkolemList)

instance skolemNotYetPresentOrDiscardableD :: SkolemNotYetPresentOrDiscardable DiscardableSkolem skolemList
else instance skolemNotYetPresentOrDiscardableO :: SkolemNotYetPresent o skolemList => SkolemNotYetPresentOrDiscardable o skolemList

class MakeInternalSkolemStack (skolem :: Type) (ptr :: Ptr) (skolems :: SkolemList) (skolemsInternal :: SkolemList) | skolem ptr skolems -> skolemsInternal

instance makeInternalSkolemStackDiscardable :: MakeInternalSkolemStack DiscardableSkolem ptr skolems skolems
else instance makeInternalSkolemStack :: MakeInternalSkolemStack skolem ptr skolems (SkolemListCons (SkolemPairC skolem ptr) skolems)

class AudioUnitEq (a :: AudioUnit) (b :: AudioUnit) (tf :: Type) | a b -> tf

instance audioUnitEqTSinOsc :: AudioUnitEq (TSinOsc idx) (TSinOsc idx) True
else instance audioUnitEqTHighpass :: AudioUnitEq (THighpass idx) (THighpass idx) True
else instance audioUnitEqTGain :: AudioUnitEq (TGain idx) (TGain idx) True
else instance audioUnitEqTSpeaker :: AudioUnitEq (TSpeaker idx) (TSpeaker idx) True
else instance audioUnitEqFalse :: AudioUnitEq a b False

class TermToInitialAudioUnit (a :: Type) (p :: Ptr) (b :: AudioUnit) | a p -> b

instance termToInitialAudioUnitSinOsc :: TermToInitialAudioUnit (SinOsc a) ptr (TSinOsc ptr)

instance termToInitialAudioUnitHighpass :: TermToInitialAudioUnit (Highpass a b c) ptr (THighpass ptr)

instance termToInitialAudioUnitGain :: TermToInitialAudioUnit (Gain a b) ptr (TGain ptr)

instance termToInitialAudioUnitSpeaker :: TermToInitialAudioUnit (Speaker a) ptr (TSpeaker ptr)

class CreationInstructions (env :: Type) (acc :: Type) (g :: Type) where
  creationInstructions :: Int -> env -> acc -> g -> Array Instruction /\ AnAudioUnit

instance creationInstructionsSinOsc :: InitialVal env acc a => CreationInstructions env acc (SinOsc a) where
  creationInstructions idx env acc (SinOsc a) =
    let
      iv' = initialVal env acc a

      AudioParameter iv = iv'
    in
      [ NewUnit idx "sinosc"
      , SetFrequency idx iv.param iv.timeOffset iv.transition
      ]
        /\ ASinOsc iv'

instance creationInstructionsHighpass :: (InitialVal env acc a, InitialVal env acc b) => CreationInstructions env acc (Highpass a b c) where
  creationInstructions idx env acc (Highpass a b _) =
    let
      aiv' = initialVal env acc a

      biv' = initialVal env acc b

      AudioParameter aiv = aiv'

      AudioParameter biv = biv'
    in
      [ NewUnit idx "highpass"
      , SetFrequency idx aiv.param aiv.timeOffset aiv.transition
      , SetQ idx biv.param biv.timeOffset biv.transition
      ]
        /\ AHighpass aiv' biv'

instance creationInstructionsGain :: InitialVal env acc a => CreationInstructions env acc (Gain a b) where
  creationInstructions idx env acc (Gain a _) =
    let
      iv' = initialVal env acc a

      AudioParameter iv = iv'
    in
      [ NewUnit idx "gain"
      , SetGain idx iv.param iv.timeOffset iv.transition
      ]
        /\ AGain iv'

instance creationInstructionsSpeaker :: CreationInstructions env acc (Speaker a) where
  creationInstructions idx env acc (Speaker _) = [] /\ ASpeaker

class ChangeInstructions (env :: Type) (acc :: Type) (g :: Type) where
  changeInstructions :: Int -> env -> acc -> g -> AnAudioUnit -> Maybe (Array Instruction /\ AnAudioUnit)

instance changeInstructionsSinOsc :: SetterVal env acc a => ChangeInstructions env acc (SinOsc a) where
  changeInstructions idx env acc (SinOsc a) = case _ of
    ASinOsc prm ->
      (setterVal :: a -> Maybe (env -> acc -> AudioParameter -> AudioParameter)) a
        <#> \f ->
            let
              iv' = f env acc prm

              AudioParameter iv = iv'
            in
              [ SetFrequency idx iv.param iv.timeOffset iv.transition ] /\ ASinOsc iv'
    _ -> Nothing

instance changeInstructionsHighpass :: (SetterVal env acc a, SetterVal env acc b) => ChangeInstructions env acc (Highpass a b c) where
  changeInstructions idx env acc (Highpass a b _) = case _ of
    AHighpass va vb ->
      let
        sa = (setterVal :: a -> Maybe (env -> acc -> AudioParameter -> AudioParameter)) a

        aiv' = maybe va (\f -> f env acc va) sa

        freqChanges = if isJust sa then let AudioParameter aiv = aiv' in [ SetFrequency idx aiv.param aiv.timeOffset aiv.transition ] else []

        sb = (setterVal :: b -> Maybe (env -> acc -> AudioParameter -> AudioParameter)) b

        biv' = maybe vb (\f -> f env acc vb) sb

        qChanges = if isJust sb then let AudioParameter biv = biv' in [ SetQ idx biv.param biv.timeOffset biv.transition ] else []
      in
        Just
          $ (freqChanges <> qChanges)
          /\ AHighpass aiv' biv'
    _ -> Nothing

instance changeInstructionsGain :: SetterVal env acc a => ChangeInstructions env acc (Gain a b) where
  changeInstructions idx env acc (Gain a _) fromMap = case fromMap of
    AGain prm ->
      (setterVal :: a -> Maybe (env -> acc -> AudioParameter -> AudioParameter)) a
        <#> \f ->
            let
              iv' = f env acc prm

              AudioParameter iv = iv'
            in
              [ SetGain idx iv.param iv.timeOffset iv.transition ] /\ AGain iv'
    _ -> Nothing

instance changeInstructionsSpeaker :: ChangeInstructions env acc (Speaker a) where
  changeInstructions _ _ _ _ _ = Nothing

class NodeListKeepSingleton (nodeListA :: NodeList) (nodeListB :: NodeList) (nodeListC :: NodeList) | nodeListA nodeListB -> nodeListC

instance nodeListKeepSingletonNil :: NodeListKeepSingleton NodeListNil NodeListNil NodeListNil

instance nodeListKeepSingletonL :: NodeListKeepSingleton (NodeListCons a NodeListNil) NodeListNil (NodeListCons a NodeListNil)

instance nodeListKeepSingletonR :: NodeListKeepSingleton NodeListNil (NodeListCons a NodeListNil) (NodeListCons a NodeListNil)

class PtrListKeepSingleton (ptrListA :: PtrList) (ptrListB :: PtrList) (ptrListC :: PtrList) | ptrListA ptrListB -> ptrListC

instance ptrListKeepSingletonNil :: PtrListKeepSingleton PtrListNil PtrListNil PtrListNil

instance ptrListKeepSingletonL :: PtrListKeepSingleton (PtrListCons a PtrListNil) PtrListNil (PtrListCons a PtrListNil)

instance ptrListKeepSingletonR :: PtrListKeepSingleton PtrListNil (PtrListCons a PtrListNil) (PtrListCons a PtrListNil)

class LookupNL (accumulator :: NodeList) (ptr :: Ptr) (graph :: NodeList) (node :: NodeList) | accumulator ptr graph -> node

instance lookupNLNil :: LookupNL accumulator ptr NodeListNil accumulator

instance lookupNLNilCons ::
  ( GetAudioUnit head headAU
  , GetPointer headAU maybePtr
  , BinEq maybePtr ptr tf
  , Gate tf (NodeListCons head NodeListNil) NodeListNil toComp
  , NodeListKeepSingleton toComp accumulator acc
  , LookupNL acc ptr tail o
  ) =>
  LookupNL accumulator ptr (NodeListCons head tail) o

class Lookup (ptr :: Ptr) (graph :: Graph) (node :: Node) | ptr graph -> node

instance lookup :: (GraphToNodeList graph nodeList, LookupNL NodeListNil ptr nodeList (NodeListCons node NodeListNil)) => Lookup ptr graph node

---------------------------
------------ NoNodesAreDuplicated
class NodeNotInNodeList (node :: Node) (nodeList :: NodeList)

instance nodeNotInNodeListNil :: NodeNotInNodeList node NodeListNil

instance nodeNotInNodeListCons ::
  ( GetAudioUnit node nodeAu
  , GetAudioUnit head headAu
  , AudioUnitEq nodeAu headAu False
  , NodeNotInNodeList node tail
  ) =>
  NodeNotInNodeList node (NodeListCons head tail)

class NoNodesAreDuplicatedInNodeList (nodeList :: NodeList)

instance noNodesAreDuplicatedInNodeListNil :: NoNodesAreDuplicatedInNodeList NodeListNil

instance noNodesAreDuplicatedInNodeListCons ::
  ( NodeNotInNodeList head tail
  , NoNodesAreDuplicatedInNodeList tail
  ) =>
  NoNodesAreDuplicatedInNodeList (NodeListCons head tail)

class NoNodesAreDuplicated (graph :: Graph)

instance noNodesAreDuplicated ::
  ( GraphToNodeList graph nodeList
  , NoNodesAreDuplicatedInNodeList nodeList
  ) =>
  NoNodesAreDuplicated graph

---------------------------
------------ AllEdgesPointToNodes
class PtrInPtrList (foundPtr :: Type) (ptr :: Ptr) (nodeList :: PtrList) (output :: Type) | foundPtr ptr nodeList -> output

instance ptrInPtrListTrue :: PtrInPtrList True a b True

instance ptrInPtrListFalseNil :: PtrInPtrList False a PtrListNil False

instance ptrInPtrListFalseCons ::
  ( BinEq ptr head foundNode
  , PtrInPtrList foundNode ptr tail o
  ) =>
  PtrInPtrList False ptr (PtrListCons head tail) o

class AudioUnitInAudioUnitList (foundNode :: Type) (audioUnit :: AudioUnit) (audioUnitList :: AudioUnitList) (output :: Type) | foundNode audioUnit audioUnitList -> output

instance audioUnitInAudioUnitListTrue :: AudioUnitInAudioUnitList True a b True

instance audioUnitInAudioUnitListFalseNil :: AudioUnitInAudioUnitList False a AudioUnitNil False

instance audioUnitInAudioUnitListFalseCons ::
  ( AudioUnitEq au head foundNode
  , AudioUnitInAudioUnitList foundNode au tail o
  ) =>
  AudioUnitInAudioUnitList False au (AudioUnitCons head tail) o

class AllPtrsInNodeList (needles :: PtrList) (haystack :: NodeList)

instance allPtrsInNodeList :: AllPtrsInNodeList PtrListNil haystack

instance allPtrsInNodeListCons ::
  ( LookupNL NodeListNil head haystack (NodeListCons x NodeListNil)
  , AllPtrsInNodeList tail haystack
  ) =>
  AllPtrsInNodeList (PtrListCons head tail) haystack

class GetEdgesAsPtrList (node :: Node) (ptrList :: PtrList) | node -> ptrList

instance getEdgesAsPtrListNoEdge :: GetEdgesAsPtrList (NodeC x NoEdge) PtrListNil

instance getEdgesAsPtrListSingleEdge :: GetEdgesAsPtrList (NodeC x (SingleEdge e)) (PtrListCons e PtrListNil)

instance getEdgesAsPtrListManyEdges :: GetEdgesAsPtrList (NodeC x (ManyEdges e l)) (PtrListCons e l)

class AllEdgesInNodeList (needles :: NodeList) (haystack :: NodeList)

instance allEdgesInNodeListNil :: AllEdgesInNodeList NodeListNil haystack

instance allEdgesInNodeListCons ::
  ( GetEdgesAsPtrList head ptrList
  , AllPtrsInNodeList ptrList haystack
  , AllEdgesInNodeList tail haystack
  ) =>
  AllEdgesInNodeList (NodeListCons head tail) haystack

class AllEdgesPointToNodes (graph :: Graph)

instance allEdgesPointToNodes :: (GraphToNodeList graph nodeList, AllEdgesInNodeList nodeList nodeList) => AllEdgesPointToNodes graph

----------------------- NoParallelEdges
------- NoParallelEdges
class PtrNotInPtrList (ptr :: Ptr) (ptrList :: PtrList)

instance ptrNotInPtrListNil :: PtrNotInPtrList ptr PtrListNil

instance ptrNotInPtrListCons ::
  ( BinEq ptr head False
  , PtrNotInPtrList ptr tail
  ) =>
  PtrNotInPtrList ptr (PtrListCons head tail)

class NoPtrsAreDuplicatedInPtrList (ptrList :: PtrList)

instance noPtrsAreDuplicatedInPtrListNil :: NoPtrsAreDuplicatedInPtrList PtrListNil

instance noPtrsAreDuplicatedInPtrListCons ::
  ( PtrNotInPtrList head tail
  , NoPtrsAreDuplicatedInPtrList tail
  ) =>
  NoPtrsAreDuplicatedInPtrList (PtrListCons head tail)

class NoParallelEdgesNL (nodeList :: NodeList)

instance noParallelEdgesNLNil :: NoParallelEdgesNL NodeListNil

instance noParallelEdgesNLConsNoEdge :: (NoParallelEdgesNL tail) => NoParallelEdgesNL (NodeListCons (NodeC n NoEdge) tail)

instance noParallelEdgesNLConsSingleEdge :: (NoParallelEdgesNL tail) => NoParallelEdgesNL (NodeListCons (NodeC n (SingleEdge e)) tail)

instance noParallelEdgesNLConsManyEdges ::
  ( NoPtrsAreDuplicatedInPtrList (PtrListCons e l)
  , NoParallelEdgesNL tail
  ) =>
  NoParallelEdgesNL (NodeListCons (NodeC n (ManyEdges e l)) tail)

class NoParallelEdges (graph :: Graph)

instance noParallelEdges ::
  ( GraphToNodeList graph nodeList
  , NoParallelEdgesNL nodeList
  ) =>
  NoParallelEdges graph

------------- UniqueTerminus
-------- UniqueTerminus
class BottomLevelNodesNL (accumulator :: NodeList) (toTraverse :: NodeList) (output :: NodeList) | accumulator toTraverse -> output

instance bottomLevelNodesNLNil :: BottomLevelNodesNL accumulator NodeListNil accumulator

instance bottomLevelNodesNLConsNoEdge :: BottomLevelNodesNL (NodeListCons (NodeC i NoEdge) accumulator) tail o => BottomLevelNodesNL accumulator (NodeListCons (NodeC i NoEdge) tail) o

instance bottomLevelNodesNLConsSingleEdge :: BottomLevelNodesNL accumulator tail o => BottomLevelNodesNL accumulator (NodeListCons (NodeC i (SingleEdge x)) tail) o

instance bottomLevelNodesNLConsManyEdges :: BottomLevelNodesNL accumulator tail o => BottomLevelNodesNL accumulator (NodeListCons (NodeC i (ManyEdges x l)) tail) o

class BottomLevelNodes (graph :: Graph) (nodeList :: NodeList) | graph -> nodeList

instance bottomLevelNodes ::
  ( GraphToNodeList graph nodeList
  , BottomLevelNodesNL NodeListNil nodeList bottomLevelNodes
  ) =>
  BottomLevelNodes graph bottomLevelNodes

class HasBottomLevelNodes (graph :: Graph)

instance hasBottomLevelNodes :: BottomLevelNodes graph (NodeListCons a b) => HasBottomLevelNodes graph

class AudioUnitInNodeList (foundNode :: Type) (audioUnit :: AudioUnit) (nodeList :: NodeList) (output :: Type) | foundNode audioUnit nodeList -> output

instance audioUnitInNodeListTrue :: AudioUnitInNodeList True a b True

instance audioUnitInNodeListFalseNil :: AudioUnitInNodeList False a NodeListNil False

instance audioUnitInNodeListFalseCons ::
  ( GetAudioUnit head headAu
  , AudioUnitEq au headAu foundNode
  , AudioUnitInNodeList foundNode au tail o
  ) =>
  AudioUnitInNodeList False au (NodeListCons head tail) o

class RemoveDuplicates (accumulator :: NodeList) (maybeWithDuplicates :: NodeList) (removed :: NodeList) | accumulator maybeWithDuplicates -> removed

instance removeDuplicatesNil :: RemoveDuplicates accumulator NodeListNil accumulator

instance removeDuplicatesCons ::
  ( GetAudioUnit head au
  , AudioUnitInNodeList False au accumulator tf
  , Gate tf accumulator (NodeListCons head accumulator) acc
  , RemoveDuplicates acc tail o
  ) =>
  RemoveDuplicates accumulator (NodeListCons head tail) o

class AssertSingleton (maybeSingleton :: NodeList) (singleton :: Node) | maybeSingleton -> singleton

instance getUniqueTerminusCons :: AssertSingleton (NodeListCons n NodeListNil) n

class NodeInNodeList (foundNode :: Type) (node :: Node) (nodeList :: NodeList) (output :: Type) | foundNode node nodeList -> output

instance nodeInNodeListTrue :: NodeInNodeList True a b True

instance nodeInNodeListFalseNil :: NodeInNodeList False a NodeListNil False

instance nodeInNodeListFalseCons ::
  ( GetAudioUnit head headAu
  , GetAudioUnit node nodeAu
  , AudioUnitEq nodeAu headAu foundNode
  , NodeInNodeList foundNode node tail o
  ) =>
  NodeInNodeList False node (NodeListCons head tail) o

class UnvisitedNodes (visited :: NodeList) (accumulator :: NodeList) (candidates :: NodeList) (unvisited :: NodeList) | visited accumulator candidates -> unvisited

instance unvisitedNodesNil :: UnvisitedNodes visited accumulator NodeListNil accumulator

instance unvisitedNodesCons ::
  ( NodeInNodeList False head visited tf
  , Gate tf accumulator (NodeListCons head accumulator) acc
  , UnvisitedNodes visited acc tail o
  ) =>
  UnvisitedNodes visited accumulator (NodeListCons head tail) o

class ToVisitSingle (accumulator :: NodeList) (graph :: NodeList) (findMeInAnEdge :: Node) (candidates :: NodeList) | accumulator graph findMeInAnEdge -> candidates

instance toVisitSingleNil :: ToVisitSingle accumulator NodeListNil findMeInAnEdge accumulator

instance toVisitSingleCons ::
  ( GetEdgesAsPtrList head edgeList
  , GetAudioUnit findMeInAnEdge au
  , GetPointer au ptr
  , PtrInPtrList False ptr edgeList tf
  , Gate tf (NodeListCons head accumulator) accumulator acc
  , ToVisitSingle acc tail findMeInAnEdge o
  ) =>
  ToVisitSingle accumulator (NodeListCons head tail) findMeInAnEdge o

class NodeListAppend (l :: NodeList) (r :: NodeList) (o :: NodeList) | l r -> o

instance nodeListAppendNilNil :: NodeListAppend NodeListNil NodeListNil NodeListNil

instance nodeListAppendNilL :: NodeListAppend NodeListNil (NodeListCons x y) (NodeListCons x y)

instance nodeListAppendNilR :: NodeListAppend (NodeListCons x y) NodeListNil (NodeListCons x y)

instance nodeListAppendCons :: (NodeListAppend b (NodeListCons c d) o) => NodeListAppend (NodeListCons a b) (NodeListCons c d) (NodeListCons a o)

class PtrListAppend (l :: PtrList) (r :: PtrList) (o :: PtrList) | l r -> o

instance ptrListAppendNilNil :: PtrListAppend PtrListNil PtrListNil PtrListNil

instance ptrListAppendNilL :: PtrListAppend PtrListNil (PtrListCons x y) (PtrListCons x y)

instance ptrListAppendNilR :: PtrListAppend (PtrListCons x y) PtrListNil (PtrListCons x y)

instance ptrListAppendCons :: (PtrListAppend b (PtrListCons c d) o) => PtrListAppend (PtrListCons a b) (PtrListCons c d) (PtrListCons a o)

class EdgeProfileChooseGreater (a :: EdgeProfile) (b :: EdgeProfile) (c :: EdgeProfile) | a b -> c

instance edgeProfileChooseGreater0 :: EdgeProfileChooseGreater NoEdge b b
else instance edgeProfileChooseGreater1 :: EdgeProfileChooseGreater a NoEdge a

class IsNodeListEmpty (nodeList :: NodeList) (tf :: Type) | nodeList -> tf

instance isNodeListEmptyNil :: IsNodeListEmpty NodeListNil True

instance isNodeListEmptyCons :: IsNodeListEmpty (NodeListCons a b) False

class ToVisit (candidatesAccumulator :: NodeList) (parentlessAccumulator :: NodeList) (graph :: NodeList) (findMeInAnEdge :: NodeList) (candidates :: NodeList) (parentless :: NodeList) | candidatesAccumulator parentlessAccumulator graph findMeInAnEdge -> candidates parentless

instance toVisitNil :: ToVisit candidatesAccumulator parentlessAccumulator graph NodeListNil candidatesAccumulator parentlessAccumulator

instance toVisitCons ::
  ( ToVisitSingle NodeListNil graph findMeInAnEdge o
  , IsNodeListEmpty o tf
  , Gate tf (NodeListCons findMeInAnEdge parentlessAccumulator) parentlessAccumulator pA
  , NodeListAppend candidatesAccumulator o cA
  , ToVisit cA pA graph tail ccA ppA
  ) =>
  ToVisit candidatesAccumulator parentlessAccumulator graph (NodeListCons findMeInAnEdge tail) ccA ppA

class TerminusLoop (graph :: NodeList) (visited :: NodeList) (visiting :: NodeList) (accumulator :: NodeList) (output :: NodeList) | graph visited visiting accumulator -> output

instance terminusLoopNil :: TerminusLoop graph visited NodeListNil accumulator accumulator

instance terminusLoopCons ::
  ( ToVisit NodeListNil NodeListNil graph (NodeListCons a b) candidatesDup parentless
  -- remove duplicates in case where we have many nodes pointing to one node
  -- in this case, it would be in candidates multiple times
  -- we remove duplicates from the parent only at the end, as we are not recursing over it
  , RemoveDuplicates NodeListNil candidatesDup candidates
  , UnvisitedNodes visited NodeListNil candidates unvisited
  , NodeListAppend unvisited visited newVisited
  , NodeListAppend accumulator parentless newAccumulator
  , TerminusLoop graph newVisited unvisited newAccumulator o
  ) =>
  TerminusLoop graph visited (NodeListCons a b) accumulator o

class UniqueTerminus (graph :: Graph) (node :: Node) | graph -> node

instance uniqueTerminus ::
  ( BottomLevelNodes graph bottomLevel
  , GraphToNodeList graph graphAsNodeList
  , TerminusLoop graphAsNodeList NodeListNil bottomLevel NodeListNil terminii
  -- we remove duplicates from the parent only after terminus loop, as we are not recursing over it in the loop
  , RemoveDuplicates NodeListNil terminii unduped
  , AssertSingleton unduped node
  ) =>
  UniqueTerminus graph node

class HasUniqueTerminus (graph :: Graph)

instance hasUniqueTerminus :: UniqueTerminus graph node => HasUniqueTerminus graph

-----------------------------------------
-------------- Need to check fully hydrated
-------------- Even though we have a unique terminus, we don't want a state where a gain is a bottom node
class AllNodesAreFullyHydratedNL (graph :: NodeList)

instance allNodesAreFullyHydratedNil :: AllNodesAreFullyHydratedNL NodeListNil

instance allNodesAreFullyHydratedConsTSinOsc :: AllNodesAreFullyHydratedNL tail => AllNodesAreFullyHydratedNL (NodeListCons (NodeC (TSinOsc a) NoEdge) tail)

instance allNodesAreFullyHydratedConsTHighpass :: AllNodesAreFullyHydratedNL tail => AllNodesAreFullyHydratedNL (NodeListCons (NodeC (THighpass a) (SingleEdge e)) tail)

instance allNodesAreFullyHydratedConsTGainSE :: AllNodesAreFullyHydratedNL tail => AllNodesAreFullyHydratedNL (NodeListCons (NodeC (TGain a) (SingleEdge e)) tail)

instance allNodesAreFullyHydratedConsTGainME :: AllNodesAreFullyHydratedNL tail => AllNodesAreFullyHydratedNL (NodeListCons (NodeC (TGain a) (ManyEdges e l)) tail)

instance allNodesAreFullyHydratedConsTSpeakerSE :: AllNodesAreFullyHydratedNL tail => AllNodesAreFullyHydratedNL (NodeListCons (NodeC (TSpeaker a) (SingleEdge e)) tail)

instance allNodesAreFullyHydratedConsTSpeakerME :: AllNodesAreFullyHydratedNL tail => AllNodesAreFullyHydratedNL (NodeListCons (NodeC (TSpeaker a) (ManyEdges e l)) tail)

class AllNodesAreFullyHydrated (graph :: Graph)

instance allNodesAreFullyHydrated :: (GraphToNodeList graph nodeList, AllNodesAreFullyHydratedNL nodeList) => AllNodesAreFullyHydrated graph

class NodeIsOutputDevice (node :: Node)

instance nodeIsOutputDeviceTSpeaker :: NodeIsOutputDevice (NodeC (TSpeaker a) x)

class GraphIsRenderable (graph :: Graph)

instance graphIsRenderable ::
  ( NoNodesAreDuplicated graph
  , AllEdgesPointToNodes graph
  , NoParallelEdges graph
  , HasBottomLevelNodes graph
  , UniqueTerminus graph terminus
  , NodeIsOutputDevice terminus
  , AllNodesAreFullyHydrated graph
  ) =>
  GraphIsRenderable graph

-- for any given step - worth it?
class GraphIsCoherent (graph :: Graph)

instance graphIsCoherent ::
  ( NoNodesAreDuplicated graph
  , AllEdgesPointToNodes graph
  , NoParallelEdges graph
  ) =>
  GraphIsCoherent graph

-- create (hpf and gain can start empty)
-- get (uses a getter on a node to get another node, think optics)
-- remove (leaves a hole, no attempt to reconstitute chain)
-- destroy (destroys all connected nodes)
-- replace (for hpf and gain)
-- add (for gain and hpf)
data AudioParameterTransition
  = NoRamp
  | LinearRamp
  | ExponentialRamp
  | Immediately

derive instance eqAudioParameterTransition :: Eq AudioParameterTransition

derive instance genericAudioParameterTransition :: Generic AudioParameterTransition _

instance showAudioParameterTransition :: Show AudioParameterTransition where
  show = genericShow

data Instruction
  = Stop Int
  | Free Int
  | DisconnectXFromY Int Int -- id id
  | ConnectXToY Int Int
  | NewUnit Int String
  | SetFrequency Int Number Number AudioParameterTransition -- frequency
  | SetThreshold Int Number Number AudioParameterTransition -- threshold
  | SetKnee Int Number Number AudioParameterTransition -- knee
  | SetRatio Int Number Number AudioParameterTransition -- ratio
  | SetAttack Int Number Number AudioParameterTransition -- attack
  | SetRelease Int Number Number AudioParameterTransition -- release
  | SetBuffer Int Int (Array (Array Number)) -- buffer
  | SetQ Int Number Number AudioParameterTransition -- q
  | SetPlaybackRate Int Number Number AudioParameterTransition -- playback rate
  | SetPeriodicWave Int (Array Number) (Array Number) -- periodic wave
  | SetCurve Int (Array Number) -- curve
  | SetOversample Int String -- oversample
  | SetLoopStart Int Number Boolean -- loop start
  | SetLoopEnd Int Number Boolean -- loop end
  | SetPan Int Number Number AudioParameterTransition -- pan for pan node
  | SetGain Int Number Number AudioParameterTransition -- gain for gain node, boolean if is start
  | SetDelay Int Number Number AudioParameterTransition -- delay for delay node
  | SetOffset Int Number Number AudioParameterTransition -- offset for const node
  | SetCustomParam Int String Number Number AudioParameterTransition -- for audio worklet nodes
  | SetConeInnerAngle Int Number
  | SetConeOuterAngle Int Number
  | SetConeOuterGain Int Number
  | SetDistanceModel Int String
  | SetMaxDistance Int Number
  | SetOrientationX Int Number Number AudioParameterTransition
  | SetOrientationY Int Number Number AudioParameterTransition
  | SetOrientationZ Int Number Number AudioParameterTransition
  | SetPanningModel Int String
  | SetPositionX Int Number Number AudioParameterTransition
  | SetPositionY Int Number Number AudioParameterTransition
  | SetPositionZ Int Number Number AudioParameterTransition
  | SetRefDistance Int Number
  | SetRolloffFactor Int Number

derive instance eqInstruction :: Eq Instruction

derive instance genericInstruction :: Generic Instruction _

instance showInstruction :: Show Instruction where
  show = genericShow

instance ordInstruction :: Ord Instruction where
  compare (Stop x) (Stop y) = compare x y
  compare (Stop _) _ = LT
  compare (DisconnectXFromY x _) (DisconnectXFromY y _) = compare x y
  compare (DisconnectXFromY _ _) _ = LT
  compare (Free x) (Free y) = compare x y
  compare (Free _) _ = LT
  compare _ (Stop _) = GT
  compare _ (DisconnectXFromY _ _) = GT
  compare _ (Free _) = GT
  compare (ConnectXToY x _) (ConnectXToY y _) = compare x y
  compare (ConnectXToY _ _) _ = GT
  compare (NewUnit x _) (NewUnit y _) = compare x y
  compare (NewUnit _ _) _ = GT
  compare _ (ConnectXToY _ _) = LT
  compare _ (NewUnit _ _) = LT
  compare _ _ = EQ

testCompare :: Instruction -> Instruction -> Ordering
testCompare a b = case compare a b of
  EQ -> compare (show a) (show b)
  x -> x

type AudioState' env
  = { env :: env
    , acc :: Void
    , currentIdx :: Int
    , instructions :: Array Instruction
    , internalNodes :: M.Map Int AnAudioUnit
    , internalEdges :: M.Map Int (Set Int)
    }

type AudioState env a
  = WriterT (Endo Function (AudioState' env)) (State (AudioState' env)) a

newtype Frame (env :: Type) (proof :: Type) (iu :: Universe) (ou :: Universe) (a :: Type)
  = Frame (AudioState env a)

data Frame0

type InitialFrame env acc og
  = Frame env Frame0 (UniverseC D0 InitialGraph SkolemListNil acc) og Unit

foreign import data Scene :: Type -> Type -> Type

--type role Scene representational representational
asScene :: forall env proof. (env -> M.Map Int AnAudioUnit /\ M.Map Int (Set Int) /\ Array Instruction /\ (Scene env proof)) -> Scene env proof
asScene = unsafeCoerce

oneFrame :: forall env proof. Scene env proof -> env -> M.Map Int AnAudioUnit /\ M.Map Int (Set Int) /\ Array Instruction /\ (Scene env proof)
oneFrame = unsafeCoerce

instance universeIsCoherent ::
  GraphIsRenderable graph =>
  UniverseIsCoherent (UniverseC ptr graph SkolemListNil acc) where
  assertCoherence _ = unit

class UniverseIsCoherent (u :: Universe) where
  assertCoherence :: forall env proof i x. Frame env proof i u x -> Unit

start ::
  forall env acc g0.
  UniverseIsCoherent g0 =>
  acc ->
  InitialFrame env acc g0 ->
  (forall proof. Frame env proof g0 g0 Unit -> Scene env proof) ->
  Scene env Frame0
start a b = makeScene0T (a /\ b)

makeScene0T ::
  forall env acc g0.
  UniverseIsCoherent g0 =>
  acc /\ InitialFrame env acc g0 ->
  (forall proof. Frame env proof g0 g0 Unit -> Scene env proof) ->
  Scene env Frame0
makeScene0T (acc /\ fr@(Frame f)) trans = asScene go
  where
  go env =
    let
      os =
        execState (map fst (runWriterT f))
          (initialAudioState env acc)

      scene = trans $ Frame $ WriterT (pure (Tuple unit (Endo (const $ os))))
    in
      os.internalNodes /\ os.internalEdges /\ os.instructions /\ scene

infixr 6 makeScene0T as @@!>

makeScene' ::
  forall env proofA proofB g0 g1 g2.
  UniverseIsCoherent g1 =>
  (Frame env proofB g0 g1 Unit -> Frame env proofB g0 g2 Unit) ->
  Frame env proofA g0 g1 Unit ->
  (Frame env proofB g0 g2 Unit -> Scene env proofB) ->
  Scene env proofA
makeScene' mogrify fr trans = asScene go
  where
  Frame f = mogrify ((unsafeCoerce :: Frame env proofA g0 g1 Unit -> Frame env proofB g0 g1 Unit) fr)

  go env =
    let
      rt = runWriterT f

      stateM = map fst rt

      initialSt = map snd rt

      ias = initialAudioState env (unsafeCoerce unit)

      os =
        execState
          ( do
              Endo s <- initialSt
              withState (const $ (s ias) { env = env, instructions = [] }) stateM
          )
          ias

      scene = trans $ Frame $ WriterT (pure (Tuple unit (Endo (const $ os))))
    in
      os.internalNodes /\ os.internalEdges /\ os.instructions /\ ((unsafeCoerce :: Scene env proofB -> Scene env proofA) scene)

makeScene ::
  forall env proofA g0 g1.
  UniverseIsCoherent g1 =>
  Frame env proofA g0 g1 Unit ->
  (forall proofB. Frame env proofB g0 g1 Unit -> Scene env proofB) ->
  Scene env proofA
makeScene = makeScene' identity

makeChangingScene ::
  forall env proofA g0 g1 edge a.
  TerminalIdentityEdge g1 edge =>
  Change edge a env g1 =>
  UniverseIsCoherent g1 =>
  a ->
  Frame env proofA g0 g1 Unit ->
  (forall proofB. Frame env proofB g0 g1 Unit -> Scene env proofB) ->
  Scene env proofA
makeChangingScene a = makeScene' (flip iapplySecond (change a))

makeChangingSceneLoop ::
  forall env proofA g0 g1 edge a.
  TerminalIdentityEdge g1 edge =>
  Change edge a env g1 =>
  UniverseIsCoherent g1 =>
  a ->
  Frame env proofA g0 g1 Unit ->
  Scene env proofA
makeChangingSceneLoop a = fix \f -> flip (makeScene' (flip iapplySecond (change a))) f

infixr 6 makeScene as @!>

loop ::
  forall env proof g0 g1.
  UniverseIsCoherent g1 =>
  Frame env proof g0 g1 Unit ->
  Scene env proof
loop = fix \f -> flip (makeScene' identity) f

unFrame :: forall env proof i o a. Frame env proof i o a -> AudioState env a
unFrame (Frame state) = state

initialAudioState :: forall env acc. env -> acc -> AudioState' env
initialAudioState env acc =
  { env: env
  , acc: unsafeCoerce acc
  , currentIdx: 0
  , instructions: []
  , internalNodes: M.empty
  , internalEdges: M.empty
  }

instance sceneIxFunctor :: IxFunctor (Frame env proof) where
  imap f (Frame a) = Frame (f <$> a)

instance sceneIxApplicative :: IxApply (Frame env proof) where
  iapply (Frame f) (Frame a) = Frame (f <*> a)

instance sceneIxApply :: IxApplicative (Frame env proof) where
  ipure a = Frame $ pure a

instance sceneIxBind :: IxBind (Frame env proof) where
  ibind (Frame monad) function = Frame (monad >>= (unFrame <<< function))

instance sceneIxMonad :: IxMonad (Frame env proof)

class IxSpy m i o a where
  ixspy :: m i o a -> m i o a

instance ixspyI :: (Warn ((Text "ixspy") ^^ (Quote (m i o a)))) => IxSpy m i o a where
  ixspy = identity

defaultParam :: AudioParameter'
defaultParam = { param: 0.0, timeOffset: 0.0, transition: LinearRamp, forceSet: false }

type AudioParameter'
  = { param :: Number
    , timeOffset :: Number
    , transition :: AudioParameterTransition
    , forceSet :: Boolean
    }

newtype AudioParameter
  = AudioParameter AudioParameter'

param :: Number -> AudioParameter
param =
  AudioParameter
    <<< defaultParam
        { param = _
        }

derive newtype instance eqAudioParameter :: Eq AudioParameter

derive newtype instance showAudioParameter :: Show AudioParameter

class InitialVal env acc a where
  initialVal :: env -> acc -> a -> AudioParameter

instance initialValNumber :: InitialVal env acc Number where
  initialVal _ _ a = AudioParameter $ defaultParam { param = a }

instance initialValAudioParameter :: InitialVal env acc AudioParameter where
  initialVal _ _ = identity

instance initialValFunction :: InitialVal env acc (env -> acc -> AudioParameter) where
  initialVal env acc f = f env acc

instance initialValTuple :: InitialVal env acc a => InitialVal env acc (Tuple a b) where
  initialVal env acc a = initialVal env acc $ fst a

class SetterVal env acc a where
  setterVal :: a -> Maybe (env -> acc -> AudioParameter -> AudioParameter)

instance setterValNumber :: SetterVal env acc Number where
  setterVal _ = Nothing

instance setterValAudioParameter :: SetterVal env acc AudioParameter where
  setterVal _ = Nothing

instance setterValTuple :: SetterVal env acc (Tuple a (env -> acc -> AudioParameter -> AudioParameter)) where
  setterVal = Just <<< snd

instance setterValTupleN :: SetterVal env acc (Tuple a (env -> acc -> AudioParameter -> Number)) where
  setterVal = Just <<< ((map <<< map <<< map) param) <<< snd

instance setterValFunction :: SetterVal env acc (env -> acc -> AudioParameter -> AudioParameter) where
  setterVal = Just

instance setterValFunctionN :: SetterVal env acc (env -> acc -> AudioParameter -> Number) where
  setterVal = Just <<< (map <<< map <<< map) param

data AudioUnitRef (ptr :: Ptr)
  = AudioUnitRef Int

data SinOsc a
  = SinOsc a

data Dup a b
  = Dup a b

data AnAudioUnit
  = ASinOsc AudioParameter
  | AHighpass AudioParameter AudioParameter
  | AGain AudioParameter
  | ASpeaker

derive instance eqAnAudioUnit :: Eq AnAudioUnit

derive instance genericAnAudioUnit :: Generic AnAudioUnit _

instance showAnAudioUnit :: Show AnAudioUnit where
  show = genericShow

data Highpass a b c
  = Highpass a b c

data Highpass_ a b
  = Highpass_ a b

data Gain a b
  = Gain a b

data Speaker a
  = Speaker a

class EdgeListable a (b :: PtrList) | a -> b where
  getPointers' :: a -> PtrArr b

instance edgeListableUnit :: EdgeListable Unit PtrListNil where
  getPointers' _ = PtrArr []

instance edgeListableTuple :: EdgeListable x y => EdgeListable (Tuple (AudioUnitRef ptr) x) (PtrListCons ptr y) where
  getPointers' (Tuple (AudioUnitRef i) x) = let PtrArr o = getPointers' x in PtrArr ([ i ] <> o)

newtype PtrArr a
  = PtrArr (Array Int)

data DiscardableSkolem

class GetSkolemFromRecursiveArgument (a :: Type) (skolem :: Type) | a -> skolem

instance getSkolemFromRecursiveArgumentF :: GetSkolemFromRecursiveArgument ((Proxy skolem) -> b) skolem
else instance getSkolemFromRecursiveArgumentC :: GetSkolemFromRecursiveArgument b DiscardableSkolem

class ToSkolemizedFunction (a :: Type) (skolem :: Type) (b :: Type) | a skolem -> b where
  toSkolemizedFunction :: a -> (Proxy skolem -> b)

instance toSkolemizedFunctionFunction :: ToSkolemizedFunction (Proxy skolem -> b) skolem b where
  toSkolemizedFunction = identity
else instance toSkolemizedFunctionConst :: ToSkolemizedFunction b skolem b where
  toSkolemizedFunction = const

class GetSkolemizedFunctionFromAU (a :: Type) (skolem :: Type) (b :: Type) | a skolem -> b where
  getSkolemizedFunctionFromAU :: a -> (Proxy skolem -> b)

instance getSkolemizedFunctionFromAUHighpass :: ToSkolemizedFunction i skolem o => GetSkolemizedFunctionFromAU (Highpass a b i) skolem o where
  getSkolemizedFunctionFromAU (Highpass a b c) = toSkolemizedFunction c

instance getSkolemizedFunctionFromAUGain :: ToSkolemizedFunction i skolem o => GetSkolemizedFunctionFromAU (Gain a i) skolem o where
  getSkolemizedFunctionFromAU (Gain a b) = toSkolemizedFunction b

instance getSkolemizedFunctionFromAUSpeaker :: ToSkolemizedFunction i skolem o => GetSkolemizedFunctionFromAU (Speaker i) skolem o where
  getSkolemizedFunctionFromAU (Speaker a) = toSkolemizedFunction a

class AsEdgeProfile a (b :: EdgeProfile) | a -> b where
  getPointers :: a -> PtrArr b

instance asEdgeProfileAR :: AsEdgeProfile (AudioUnitRef ptr) (SingleEdge ptr) where
  getPointers (AudioUnitRef i) = PtrArr [ i ]

instance asEdgeProfileTupl :: EdgeListable x y => AsEdgeProfile (Tuple (AudioUnitRef ptr) x) (ManyEdges ptr y) where
  getPointers (Tuple (AudioUnitRef i) el) = let PtrArr o = getPointers' el in PtrArr ([ i ] <> o)

class Create (a :: Type) (env :: Type) (i :: Universe) (o :: Universe) (x :: Type) | a env i -> o x where
  create :: forall proof. a -> Frame env proof i o x

creationStep ::
  forall env acc g.
  CreationInstructions env acc g =>
  Proxy acc ->
  g ->
  AudioState env Int
creationStep _ g = do
  { currentIdx, env, acc } <- get
  let
    renderable /\ internal = creationInstructions currentIdx env (unsafeCoerce acc :: acc) g
  modify_
    ( \i ->
        i
          { currentIdx = currentIdx + 1
          , internalNodes = M.insert currentIdx internal i.internalNodes
          , instructions = i.instructions <> renderable
          }
    )
  pure currentIdx

type ProxyCC acc skolem ptr innerTerm env i o
  = Proxy (acc /\ skolem /\ ptr /\ innerTerm /\ env /\ i /\ o)

createAndConnect ::
  forall env acc proof g (ptr :: BinL) skolem c (i :: Universe) (o :: Universe) innerTerm eprof.
  GetSkolemizedFunctionFromAU g skolem c =>
  AsEdgeProfile innerTerm eprof =>
  CreationInstructions env acc g =>
  Create c env i o innerTerm =>
  Proxy (acc /\ skolem /\ (Proxy ptr) /\ innerTerm /\ env /\ (Proxy i) /\ (Proxy o)) ->
  g ->
  Frame env proof i o Int
createAndConnect _ g =
  Frame
    $ do
        idx <- cs
        let
          (Frame mc) =
            (create :: c -> Frame env proof i o innerTerm)
              ( ((getSkolemizedFunctionFromAU :: g -> (Proxy skolem -> c)) g)
                  Proxy
              )
        oc <- mc
        let
          PtrArr o = getPointers oc
        modify_
          ( \i ->
              i
                { internalEdges =
                  M.insertWith S.union idx (S.fromFoldable o) i.internalEdges
                , instructions =
                  i.instructions
                    <> map (flip ConnectXToY idx) o
                }
          )
        pure idx
  where
  cs = creationStep (Proxy :: _ acc) g

data Focus a
  = Focus a

-- end of the line in tuples
instance createUnit ::
  Create Unit env u u Unit where
  create = Frame <<< pure

instance createTuple ::
  (Create x env u0 u1 x', Create y env u1 u2 y') =>
  Create (x /\ y) env u0 u2 (x' /\ y') where
  create (x /\ y) = Frame $ Tuple <$> x' <*> y'
    where
    Frame x' = (create :: forall proof. x -> Frame env proof u0 u1 x') x

    Frame y' = (create :: forall proof. y -> Frame env proof u1 u2 y') y

instance createIdentity :: Create x env i o r => Create (Identity x) env i o r where
  create (Identity x) = create x

instance createFocus :: Create x env i o r => Create (Focus x) env i o r where
  create (Focus x) = create x

instance createProxy ::
  ( LookupSkolem skolem skolems ptr
  , BinToInt ptr
  ) =>
  Create
    (Proxy skolem)
    env
    (UniverseC next graph skolems acc)
    (UniverseC next graph skolems acc)
    (AudioUnitRef ptr) where
  create _ = Frame (pure $ AudioUnitRef $ toInt' (Proxy :: Proxy ptr))

instance createDup ::
  ( SkolemNotYetPresent skolem skolems
  , BinToInt ptr
  --, Warn (Text "Starting" ^^ Quote (Proxy ptr))
  , Create
      a
      env
      (UniverseC ptr graphi skolems acc)
      (UniverseC midptr graphm skolems acc)
      ignore
  --, Warn (Text "Started" ^^ Quote (Proxy graphi))
  , Create
      b
      env
      (UniverseC midptr graphm (SkolemListCons (SkolemPairC skolem ptr) skolems) acc)
      (UniverseC outptr grapho (SkolemListCons (SkolemPairC skolem ptr) skolems) acc)
      (AudioUnitRef midptr)
  --, Warn (Text "Going" ^^ Quote (Proxy graphm))
  --, (Warn (Text "ptr" ^^ Quote (Proxy ptr) ^^ Text "midptr" ^^ Quote (Proxy midptr)))
  ) =>
  Create
    (Dup a (Proxy skolem -> b))
    env
    (UniverseC ptr graphi skolems acc)
    (UniverseC outptr grapho skolems acc)
    (AudioUnitRef midptr) where
  create (Dup a f) = Frame $ x *> y
    where
    Frame x =
      ( create ::
          forall proof.
          a ->
          Frame env proof
            (UniverseC ptr graphi skolems acc)
            (UniverseC midptr graphm skolems acc)
            ignore
      )
        a

    Frame y =
      ( create ::
          forall proof.
          b ->
          Frame env proof
            (UniverseC midptr graphm (SkolemListCons (SkolemPairC skolem ptr) skolems) acc)
            (UniverseC outptr grapho (SkolemListCons (SkolemPairC skolem ptr) skolems) acc)
            (AudioUnitRef midptr)
      )
        (f (Proxy :: _ skolem))

instance createSinOsc ::
  ( InitialVal env acc a
  , BinToInt ptr
  --, Warn (Text "In SinOsc created" ^^ Quote (Proxy ptr))
  , BinSucc ptr next
  --, Warn (Text "In SinOsc next" ^^ Quote (Proxy next))
  , GraphToNodeList graph nodeList
  ) =>
  Create
    (SinOsc a)
    env
    (UniverseC ptr graph skolems acc)
    ( UniverseC next
        (GraphC (NodeC (TSinOsc ptr) NoEdge) nodeList)
        skolems
        acc
    )
    (AudioUnitRef ptr) where
  create = Frame <<< map AudioUnitRef <<< creationStep (Proxy :: _ acc)

instance createHighpass ::
  ( InitialVal env acc a
  , InitialVal env acc b
  , GetSkolemFromRecursiveArgument fc skolem
  , ToSkolemizedFunction fc skolem c
  , SkolemNotYetPresentOrDiscardable skolem skolems
  , MakeInternalSkolemStack skolem ptr skolems skolemsInternal
  , BinToInt ptr
  , BinSucc ptr next
  , Create
      c
      env
      (UniverseC next graphi skolemsInternal acc)
      (UniverseC outptr grapho skolemsInternal acc)
      term
  , AsEdgeProfile term (SingleEdge op)
  , GraphToNodeList grapho nodeList
  ) =>
  Create
    (Highpass a b fc)
    env
    (UniverseC ptr graphi skolems acc)
    ( UniverseC
        outptr
        (GraphC (NodeC (THighpass ptr) (SingleEdge op)) nodeList)
        skolems
        acc
    )
    (AudioUnitRef ptr) where
  create =
    Frame <<< map AudioUnitRef <<< unFrame
      <<< createAndConnect (Proxy :: ProxyCC acc skolem (Proxy ptr) term env (Proxy (UniverseC next graphi skolemsInternal acc)) (Proxy (UniverseC outptr grapho skolemsInternal acc)))

instance createGain ::
  ( InitialVal env acc a
  --, Warn (Text "In gain" ^^ Quote (Proxy skolems))
  , GetSkolemFromRecursiveArgument fb skolem
  , ToSkolemizedFunction fb skolem b
  , SkolemNotYetPresentOrDiscardable skolem skolems
  , MakeInternalSkolemStack skolem ptr skolems skolemsInternal
  , BinToInt ptr
  , BinSucc ptr next
  , Create
      b
      env
      (UniverseC next graphi skolemsInternal acc)
      (UniverseC outptr grapho skolemsInternal acc)
      term
  --, Warn (Text "In gain" ^^ Quote (Proxy skolems) ^^ Quote (Proxy graphi) ^^ Quote (Proxy grapho))
  , AsEdgeProfile term eprof
  , GraphToNodeList grapho nodeList
  ) =>
  Create
    (Gain a fb)
    env
    (UniverseC ptr graphi skolems acc)
    ( UniverseC
        outptr
        (GraphC (NodeC (TGain ptr) eprof) nodeList)
        skolems
        acc
    )
    (AudioUnitRef ptr) where
  create ::
    forall proof.
    Gain a fb ->
    Frame env proof (UniverseC ptr graphi skolems acc)
      ( UniverseC
          outptr
          (GraphC (NodeC (TGain ptr) eprof) nodeList)
          skolems
          acc
      )
      (AudioUnitRef ptr)
  create =
    Frame <<< map AudioUnitRef <<< unFrame
      <<< (createAndConnect (Proxy :: ProxyCC acc skolem (Proxy ptr) term env (Proxy (UniverseC next graphi skolemsInternal acc)) (Proxy (UniverseC outptr grapho skolemsInternal acc))))

-- toSkolemizedFunction :: a -> (Proxy skolem -> b)
instance createSpeaker ::
  ( ToSkolemizedFunction a DiscardableSkolem a
  , BinToInt ptr
  , BinSucc ptr next
  , Create
      a
      env
      (UniverseC next graphi skolems acc)
      (UniverseC outptr grapho skolems acc)
      term
  , AsEdgeProfile term eprof
  , GraphToNodeList grapho nodeList
  ) =>
  Create
    (Speaker a)
    env
    (UniverseC ptr graphi skolems acc)
    ( UniverseC
        outptr
        (GraphC (NodeC (TSpeaker ptr) eprof) nodeList)
        skolems
        acc
    )
    (AudioUnitRef ptr) where
  create =
    Frame <<< map AudioUnitRef <<< unFrame
      <<< (createAndConnect (Proxy :: ProxyCC acc DiscardableSkolem (Proxy ptr) term env (Proxy (UniverseC next graphi skolems acc)) (Proxy (UniverseC outptr grapho skolems acc))))

class TerminalNode (u :: Universe) (ptr :: Ptr) | u -> ptr

instance terminalNode ::
  ( GetGraph i g
  , UniqueTerminus g t
  , GetAudioUnit t u
  , GetPointer u ptr
  ) =>
  TerminalNode i ptr

class TerminalIdentityEdge (u :: Universe) (prof :: EdgeProfile) | u -> prof

instance terminalIdentityEdge :: (TerminalNode i ptr) => TerminalIdentityEdge i (SingleEdge ptr)

change ::
  forall edge a x i env proof.
  TerminalIdentityEdge i edge =>
  Change edge a env i =>
  a -> Frame env proof i i Unit
change = change' (Proxy :: _ edge)

class Change (p :: EdgeProfile) (a :: Type) (env :: Type) (o :: Universe) where
  change' :: forall proof. Proxy p -> a -> Frame env proof o o Unit

class ModifyRes (tag :: Type) (p :: Ptr) (i :: Node) (mod :: NodeList) (plist :: EdgeProfile) | tag p i -> mod plist

instance modifyResSinOsc :: ModifyRes (SinOsc a) p (NodeC (TSinOsc p) e) (NodeListCons (NodeC (TSinOsc p) e) NodeListNil) e
else instance modifyResHighpass :: ModifyRes (Highpass a b c) p (NodeC (THighpass p) e) (NodeListCons (NodeC (THighpass p) e) NodeListNil) e
else instance modifyResGain :: ModifyRes (Gain a b) p (NodeC (TGain p) e) (NodeListCons (NodeC (TGain p) e) NodeListNil) e
else instance modifyResSpeaker :: ModifyRes (Speaker a) p (NodeC (TSpeaker p) e) (NodeListCons (NodeC (TSpeaker p) e) NodeListNil) e
else instance modifyResMiss :: ModifyRes tag p n NodeListNil NoEdge

class Modify' (tag :: Type) (p :: Ptr) (i :: NodeList) (mod :: NodeList) (nextP :: EdgeProfile) | tag p i -> mod nextP

instance modifyNil :: Modify' tag p NodeListNil NodeListNil NoEdge

instance modifyCons ::
  ( ModifyRes tag p head headResAsList headPlist
  , Modify' tag p tail tailResAsList tailPlist
  , NodeListAppend headResAsList tailResAsList o
  , EdgeProfileChooseGreater headPlist tailPlist plist
  ) =>
  Modify' tag p (NodeListCons head tail) o plist

class Modify (tag :: Type) (p :: Ptr) (i :: Universe) (nextP :: EdgeProfile) | tag p i -> nextP

instance modify :: (GraphToNodeList ig il, Modify' tag p il mod nextP, AssertSingleton mod x) => Modify tag p (UniverseC i ig sk acc) nextP

changeAudioUnit ::
  forall g env proof acc (inuniv :: Universe) (p :: BinL) (nextP :: EdgeProfile) univ.
  GetAccumulator inuniv acc =>
  ChangeInstructions env acc g =>
  BinToInt p =>
  Modify g p inuniv nextP =>
  Proxy ((Proxy p) /\ acc /\ (Proxy nextP) /\ env /\ Proxy inuniv) -> g -> Frame env proof univ inuniv Unit
changeAudioUnit _ g =
  Frame
    $ do
        { env, acc } <- get
        let
          ptr = toInt' (Proxy :: _ p)
        anAudioUnit' <- M.lookup ptr <$> gets _.internalNodes
        case anAudioUnit' of
          Just anAudioUnit -> case changeInstructions ptr env (unsafeCoerce acc :: acc) g anAudioUnit of
            Just (instr /\ au) ->
              modify_
                ( \i ->
                    i
                      { internalNodes = M.insert ptr au i.internalNodes
                      , instructions = i.instructions <> instr
                      }
                )
            Nothing -> pure unit
          Nothing -> pure unit

instance changeNoEdge ::
  Change NoEdge g env inuniv where
  change' _ _ = Frame (pure unit)

instance changeSkolem ::
  Change (SingleEdge p) (Proxy skolem) env inuniv where
  change' _ _ = Frame (pure unit)

instance changeIdentity :: Change (SingleEdge p) x env inuniv => Change (SingleEdge p) (Identity x) env inuniv where
  change' p (Identity x) = change' p x

instance changeFocus :: Change (SingleEdge p) x env inuniv => Change (SingleEdge p) (Focus x) env inuniv where
  change' p (Focus x) = change' p x

instance changeMany2 ::
  ( Change (SingleEdge p) x env inuniv
  , Change (ManyEdges a b) y env inuniv
  ) =>
  Change (ManyEdges p (PtrListCons a b)) (x /\ y) env inuniv where
  change' _ (x /\ y) = Ix.do
    (change' :: forall proof. Proxy (SingleEdge p) -> x -> Frame env proof inuniv inuniv Unit) Proxy x
    (change' :: forall proof. Proxy (ManyEdges a b) -> y -> Frame env proof inuniv inuniv Unit) Proxy y

instance changeMany1 ::
  Change (SingleEdge p) a env inuniv =>
  Change (ManyEdges p PtrListNil) (a /\ Unit) env inuniv where
  change' _ (a /\ _) = (change' :: forall proof. Proxy (SingleEdge p) -> a -> Frame env proof inuniv inuniv Unit) Proxy a

instance changeSinOsc ::
  ( GetAccumulator inuniv acc
  , SetterVal env acc a
  , BinToInt p
  , Modify (SinOsc a) p inuniv nextP
  ) =>
  Change (SingleEdge p) (SinOsc a) env inuniv where
  change' _ = changeAudioUnit (Proxy :: Proxy ((Proxy p) /\ acc /\ (Proxy nextP) /\ env /\ Proxy inuniv))

instance changeHighpass ::
  ( GetAccumulator inuniv acc
  , SetterVal env acc a
  , SetterVal env acc b
  , BinToInt p
  , GetSkolemFromRecursiveArgument fc skolem
  , ToSkolemizedFunction fc skolem c
  , Modify (Highpass a b c) p inuniv nextP
  , Change nextP c env inuniv
  ) =>
  Change (SingleEdge p) (Highpass a b fc) env inuniv where
  change' _ (Highpass a b fc) =
    let
      c = (((toSkolemizedFunction :: fc -> (Proxy skolem -> c)) fc) Proxy)
    in
      Ix.do
        changeAudioUnit (Proxy :: Proxy (Proxy p /\ acc /\ (Proxy nextP) /\ env /\ Proxy inuniv)) (Highpass a b c)
        (change' :: forall proof. (Proxy nextP) -> c -> Frame env proof inuniv inuniv Unit) Proxy c

instance changeDup ::
  ( Create
      a
      env
      (UniverseC D0 InitialGraph (SkolemListCons (SkolemPairC skolem D0) skolems) acc)
      (UniverseC outptr grapho (SkolemListCons (SkolemPairC skolem D0) skolems) acc)
      ignore
  --, Warn ((Text "changeDup outptr for b") ^^ (Quote (Proxy p)))
  --, Warn ((Text "changeDup b") ^^ (Quote b))
  , BinToInt p
  , BinToInt outptr
  , BinToInt continuation
  , BinSub p outptr continuation
  --, Warn ((Text "changeDup continuation for a") ^^ (Quote (Proxy continuation)))
  --, Warn ((Text "changeDup a") ^^ (Quote a))
  , Change (SingleEdge p) b env inuniv
  , Change (SingleEdge continuation) a env inuniv
  ) =>
  Change (SingleEdge p) (Dup a (Proxy skolem -> b)) env inuniv where
  change' _ (Dup a f) = Ix.do
    (change' :: forall proof. (Proxy (SingleEdge p)) -> b -> Frame env proof inuniv inuniv Unit) Proxy (f Proxy)
    (change' :: forall proof. (Proxy (SingleEdge continuation)) -> a -> Frame env proof inuniv inuniv Unit) Proxy a

instance changeGain ::
  ( GetAccumulator inuniv acc
  , SetterVal env acc a
  , BinToInt p
  , GetSkolemFromRecursiveArgument fb skolem
  , ToSkolemizedFunction fb skolem b
  , Modify (Gain a b) p inuniv nextP
  , Change nextP b env inuniv
  ) =>
  Change (SingleEdge p) (Gain a fb) env inuniv where
  change' _ (Gain a fb) =
    let
      b = (((toSkolemizedFunction :: fb -> (Proxy skolem -> b)) fb) Proxy)
    in
      Ix.do
        changeAudioUnit (Proxy :: Proxy (Proxy p /\ acc /\ (Proxy nextP) /\ env /\ Proxy inuniv)) (Gain a b)
        (change' :: forall proof. (Proxy nextP) -> b -> Frame env proof inuniv inuniv Unit) Proxy b

instance changeSpeaker ::
  ( GetAccumulator inuniv acc
  , BinToInt p
  , GetSkolemFromRecursiveArgument fa skolem
  , ToSkolemizedFunction fa skolem a
  , Modify (Speaker a) p inuniv nextP
  , Change nextP a env inuniv
  ) =>
  Change (SingleEdge p) (Speaker fa) env inuniv where
  change' _ (Speaker fa) =
    let
      a = (((toSkolemizedFunction :: fa -> (Proxy skolem -> a)) fa) Proxy)
    in
      Ix.do
        changeAudioUnit (Proxy :: Proxy (Proxy p /\ acc /\ (Proxy nextP) /\ env /\ Proxy inuniv)) (Speaker a)
        (change' :: forall proof. (Proxy nextP) -> a -> Frame env proof inuniv inuniv Unit) Proxy a

--------------------- getters
cursor ::
  forall edge a x i env proof p.
  TerminalIdentityEdge i edge =>
  Cursor edge a env i p =>
  --Warn (Text "cret" ^^ Quote (Proxy p)) =>
  BinToInt p =>
  a -> Frame env proof i i (AudioUnitRef p)
cursor = cursor' (Proxy :: _ edge)

class Cursor (p :: EdgeProfile) (a :: Type) (env :: Type) (o :: Universe) (ptr :: Ptr) | p a env o -> ptr where
  cursor' :: forall proof. Proxy p -> a -> Frame env proof o o (AudioUnitRef ptr)

instance cursorRecurse :: (BinToInt head, CursorI p a env o (PtrListCons head PtrListNil)) => Cursor p a env o head where
  cursor' _ _ = Frame (pure $ AudioUnitRef (toInt' (Proxy :: Proxy head)))

class CursorRes (tag :: Type) (p :: Ptr) (i :: Node) (plist :: EdgeProfile) | tag p i -> plist

instance cursorResSinOsc :: CursorRes (SinOsc a) p (NodeC (TSinOsc p) e) e
else instance cursorResHighpass :: CursorRes (Highpass a b c) p (NodeC (THighpass p) e) e
else instance cursorResGain :: CursorRes (Gain a b) p (NodeC (TGain p) e) e
else instance cursorResSpeaker :: CursorRes (Speaker a) p (NodeC (TSpeaker p) e) e
else instance cursorResMiss :: CursorRes tag p n NoEdge

class Cursor' (tag :: Type) (p :: Ptr) (i :: NodeList) (nextP :: EdgeProfile) | tag p i -> nextP

instance cursorNil :: Cursor' tag p NodeListNil NoEdge

instance cursorCons ::
  ( CursorRes tag p head headPlist
  , Cursor' tag p tail tailPlist
  , EdgeProfileChooseGreater headPlist tailPlist plist
  ) =>
  Cursor' tag p (NodeListCons head tail) plist

class CursorX (tag :: Type) (p :: Ptr) (i :: Universe) (nextP :: EdgeProfile) | tag p i -> nextP

instance cursorX :: (GraphToNodeList ig il, Cursor' tag p il nextP) => CursorX tag p (UniverseC i ig sk acc) nextP

class CursorI (p :: EdgeProfile) (a :: Type) (env :: Type) (o :: Universe) (ptr :: PtrList) | p a env o -> ptr

instance cursorNoEdge :: CursorI NoEdge g env inuniv PtrListNil

instance cursorSkolem :: BinToInt p => CursorI (SingleEdge p) (Proxy skolem) env inuniv PtrListNil

instance cursorIdentity :: (BinToInt p, CursorI (SingleEdge p) x env inuniv o) => CursorI (SingleEdge p) (Identity x) env inuniv o

instance cursorFocus :: (BinToInt p, CursorI (SingleEdge p) x env inuniv o) => CursorI (SingleEdge p) (Focus x) env inuniv (PtrListCons p o)

instance cursorMany2 ::
  ( BinToInt p
  , BinToInt a
  , CursorI (SingleEdge p) x env inuniv o0
  , CursorI (ManyEdges a b) y env inuniv o1
  , PtrListAppend o0 o1 oo
  ) =>
  CursorI (ManyEdges p (PtrListCons a b)) (x /\ y) env inuniv oo

instance cursorMany1 ::
  (BinToInt p, CursorI (SingleEdge p) a env inuniv o) =>
  CursorI (ManyEdges p PtrListNil) (a /\ Unit) env inuniv o

-- incoming to the change will be the ptr of the inner closure, which is the actual connection -- we run the inner closure to get the ptr for the outer closure
instance cursorDup ::
  ( Create
      a
      env
      (UniverseC D0 InitialGraph (SkolemListCons (SkolemPairC skolem D0) skolems) acc)
      (UniverseC outptr grapho (SkolemListCons (SkolemPairC skolem D0) skolems) acc)
      ignore
  --, Warn ((Text "cursorDup outptr for b") ^^ (Quote (Proxy p)))
  --, Warn ((Text "cursorDup b") ^^ (Quote b))
  , BinToInt p
  , BinToInt outptr
  , BinToInt continuation
  , BinSub p outptr continuation
  --, Warn ((Text "cursorDup continuation for a") ^^ (Quote (Proxy continuation)))
  --, Warn ((Text "cursorDup outptr") ^^ (Quote (Proxy outptr)))
  --, Warn ((Text "cursorDup p") ^^ (Quote (Proxy p)))
  --, Warn ((Text "cursorDup a") ^^ (Quote a))
  , CursorI (SingleEdge p) b env inuniv o0
  , CursorI (SingleEdge continuation) a env inuniv o1
  , PtrListAppend o0 o1 oo
  ) =>
  CursorI (SingleEdge p) (Dup a (Proxy skolem -> b)) env inuniv oo

instance cursorSinOsc ::
  BinToInt p =>
  CursorI (SingleEdge p) (SinOsc a) env inuniv PtrListNil

instance cursorHighpass ::
  ( BinToInt p
  , GetSkolemFromRecursiveArgument fc skolem
  , ToSkolemizedFunction fc skolem c
  , CursorX (Highpass a b c) p inuniv nextP
  --, Warn ((Text "highpass nextp") ^^ (Quote (Proxy nextP)))
  , CursorI nextP c env inuniv o
  ) =>
  CursorI (SingleEdge p) (Highpass a b fc) env inuniv o

instance cursorGain ::
  ( BinToInt p
  , GetSkolemFromRecursiveArgument fb skolem
  , ToSkolemizedFunction fb skolem b
  --, Warn ((Text "gain cursor"))
  , CursorX (Gain a b) p inuniv nextP
  --, Warn ((Text "gain b") ^^ (Quote (Proxy b)))
  , CursorI nextP b env inuniv o
  ) =>
  CursorI (SingleEdge p) (Gain a fb) env inuniv o

instance cursorSpeaker ::
  ( BinToInt p
  --, Warn ((Text "speaker cursor"))
  , CursorX (Speaker a) p inuniv nextP
  --, Warn ((Text "speaker nextp") ^^ (Quote a))
  , CursorI nextP a env inuniv o
  ) =>
  CursorI (SingleEdge p) (Speaker a) env inuniv o

-------------------
-- connect
class AddPointerToNode (from :: Ptr) (to :: Ptr) (i :: Node) (o :: Node) | from to i -> o

instance addPointerToNodeHPFHitSE :: AddPointerToNode from to (NodeC (THighpass to) (SingleEdge e)) (NodeC (THighpass to) (SingleEdge from))
else instance addPointerToNodeGainHitSE :: AddPointerToNode from to (NodeC (TGain to) (SingleEdge e)) (NodeC (TGain to) (ManyEdges from (PtrListCons e PtrListNil)))
else instance addPointerToNodeGainHitME :: AddPointerToNode from to (NodeC (TGain to) (ManyEdges e l)) (NodeC (TGain to) (ManyEdges from (PtrListCons e l)))
else instance addPointerToNodeSpeakerHitSE :: AddPointerToNode from to (NodeC (TSpeaker to) (SingleEdge e)) (NodeC (TSpeaker to) (ManyEdges from (PtrListCons e PtrListNil)))
else instance addPointerToNodeSpeakerHitME :: AddPointerToNode from to (NodeC (TSpeaker to) (ManyEdges e l)) (NodeC (TSpeaker to) (ManyEdges from (PtrListCons e l)))
else instance addPointerToNodeMiss :: AddPointerToNode from to i i

class AddPointerToNodes (from :: Ptr) (to :: Ptr) (i :: NodeList) (o :: NodeList) | from to i -> o

instance addPointerToNodesNil :: AddPointerToNodes a b NodeListNil NodeListNil

instance addPointerToNodesCons :: (AddPointerToNode a b head headRes, AddPointerToNodes a b tail tailRes) => AddPointerToNodes a b (NodeListCons head tail) (NodeListCons headRes tailRes)

class Connect (from :: Ptr) (to :: Ptr) (i :: Universe) (o :: Universe) | from to i -> o where
  connect :: forall env proof. AudioUnitRef from -> AudioUnitRef to -> Frame env proof i o Unit

instance connectAll :: (BinToInt from, BinToInt to, GraphToNodeList graphi nodeListI, AddPointerToNodes from to nodeListI nodeListO, GraphToNodeList grapho nodeListO) => Connect from to (UniverseC ptr graphi skolems acc) (UniverseC ptr grapho skolems acc) where
  connect (AudioUnitRef fromI) (AudioUnitRef toI) =
    Frame
      $ do
          modify_
            ( \i ->
                i
                  { internalEdges = M.insertWith S.union toI (S.singleton fromI) i.internalEdges
                  , instructions = i.instructions <> [ ConnectXToY fromI toI ]
                  }
            )

----------------------------------
--- disconnect
class RemovePtrFromList (ptr :: Ptr) (i :: PtrList) (o :: PtrList) | ptr i -> o

instance removePtrFromListNil :: RemovePtrFromList ptr PtrListNil PtrListNil

instance removePtrFromListCons :: (BinEq ptr head tf, RemovePtrFromList ptr tail newTail, Gate tf newTail (PtrListCons head newTail) o) => RemovePtrFromList ptr (PtrListCons head tail) o

class RemovePointerFromNode (from :: Ptr) (to :: Ptr) (i :: Node) (o :: Node) | from to i -> o

instance removePointerFromNodeHPFHitSE :: RemovePointerFromNode from to (NodeC (THighpass to) (SingleEdge from)) (NodeC (THighpass to) NoEdge)
else instance removePointerFromNodeGainHitSE :: RemovePointerFromNode from to (NodeC (TGain to) (SingleEdge from)) (NodeC (TGain to) NoEdge)
else instance removePointerFromNodeGainHitME :: (RemovePtrFromList from (PtrListCons e (PtrListCons l r)) (PtrListCons head tail)) => RemovePointerFromNode from to (NodeC (TGain to) (ManyEdges e (PtrListCons l r))) (NodeC (TGain to) (ManyEdges head tail))
else instance removePointerFromNodeSpeakerHitSE :: RemovePointerFromNode from to (NodeC (TSpeaker to) (SingleEdge from)) (NodeC (TSpeaker to) NoEdge)
else instance removePointerFromNodeSpeakerHitME :: (RemovePtrFromList from (PtrListCons e (PtrListCons l r)) (PtrListCons head tail)) => RemovePointerFromNode from to (NodeC (TSpeaker to) (ManyEdges e (PtrListCons l r))) (NodeC (TSpeaker to) (ManyEdges head tail))
else instance removePointerFromNodeMiss :: RemovePointerFromNode from to i i

class RemovePointerFromNodes (from :: Ptr) (to :: Ptr) (i :: NodeList) (o :: NodeList) | from to i -> o

instance removePointerFromNodesNil :: RemovePointerFromNodes a b NodeListNil NodeListNil
-- Warn (Text "looping" ^^ Quote (Proxy a) ^^ Quote (Proxy b) ^^ Quote (Proxy head))
instance removePointerFromNodesCons ::
  ( RemovePointerFromNode a b head headRes
  , RemovePointerFromNodes a b tail tailRes
  ) =>
  RemovePointerFromNodes a b (NodeListCons head tail) (NodeListCons headRes tailRes)

class Disconnect (from :: Ptr) (to :: Ptr) (i :: Universe) (o :: Universe) | from to i -> o where
  disconnect :: forall env proof. AudioUnitRef from -> AudioUnitRef to -> Frame env proof i o Unit
-- Warn (Text "dcon" ^^ Quote (Proxy from) ^^ Quote (Proxy to))

instance disconnector ::
  ( BinToInt from
  , BinToInt to
  , GraphToNodeList graphi nodeListI
  , RemovePointerFromNodes from to nodeListI nodeListO
  , GraphToNodeList grapho nodeListO
  ) =>
  Disconnect from to (UniverseC ptr graphi skolems acc) (UniverseC ptr grapho skolems acc) where
  disconnect (AudioUnitRef fromI) (AudioUnitRef toI) =
    Frame
      $ do
          modify_
            ( \i ->
                i
                  { internalEdges = M.insertWith S.difference toI (S.singleton fromI) i.internalEdges
                  , instructions = i.instructions <> [ DisconnectXFromY fromI toI ]
                  }
            )

-----------------
-- destroy
class PointerNotConnected (ptr :: Ptr) (i :: Node)

instance pointerNotConnectedSinOsc :: PointerNotConnected ptr (NodeC (TSinOsc x) NoEdge)

instance pointerNotConnectedHPFNE :: PointerNotConnected ptr (NodeC (THighpass x) NoEdge)

instance pointerNotConnectedHPFSE :: BinEq ptr y False => PointerNotConnected ptr (NodeC (THighpass x) (SingleEdge y))

instance pointerNotConnectedGainNE :: PointerNotConnected ptr (NodeC (TGain x) NoEdge)

instance pointerNotConnectedGainSE :: BinEq ptr y False => PointerNotConnected ptr (NodeC (TGain x) (SingleEdge y))

instance pointerNotConnectedGainME :: PtrNotInPtrList ptr (PtrListCons y z) => PointerNotConnected ptr (NodeC (TGain x) (ManyEdges y z))

instance pointerNotConnectedSpeakerNE :: PointerNotConnected ptr (NodeC (TSpeaker x) NoEdge)

instance pointerNotConnectedSpeakerSE :: BinEq ptr y False => PointerNotConnected ptr (NodeC (TSpeaker x) (SingleEdge y))

instance pointerNotConnectedSpeakerME :: PtrNotInPtrList ptr (PtrListCons y z) => PointerNotConnected ptr (NodeC (TSpeaker x) (ManyEdges y z))

class PointerNotConnecteds (ptr :: Ptr) (i :: NodeList)

instance pointerNotConnectedsNil :: PointerNotConnecteds a NodeListNil

instance pointerNotConnectedsCons :: (PointerNotConnected a head, PointerNotConnecteds a tail) => PointerNotConnecteds a (NodeListCons head tail)

class RemovePtrFromNodeList (ptr :: Ptr) (nodeListI :: NodeList) (nodeListO :: NodeList) | ptr nodeListI -> nodeListO

instance removePtrFromNListNil :: RemovePtrFromNodeList ptr NodeListNil NodeListNil

instance removePtrFromNListCons :: (GetAudioUnit head headAu, GetPointer headAu headPtr, BinEq ptr headPtr tf, RemovePtrFromNodeList ptr tail newTail, Gate tf newTail (NodeListCons head newTail) o) => RemovePtrFromNodeList ptr (NodeListCons head tail) o

class Destroy (ptr :: Ptr) (i :: Universe) (o :: Universe) | ptr i -> o where
  destroy :: forall env proof. AudioUnitRef ptr -> Frame env proof i o Unit

instance destroyer ::
  ( BinToInt ptr
  , GraphToNodeList graphi nodeListI
  , PointerNotConnecteds ptr nodeListI
  , RemovePtrFromNodeList ptr nodeListI nodeListO
  , GraphToNodeList grapho nodeListO
  ) =>
  Destroy ptr (UniverseC x graphi skolems acc) (UniverseC x grapho skolems acc) where
  destroy (AudioUnitRef ptrI) =
    Frame
      $ do
          modify_
            ( \i ->
                i
                  { internalNodes = M.delete ptrI i.internalNodes
                  , internalEdges = M.delete ptrI i.internalEdges
                  , instructions = i.instructions <> [ Free ptrI, Stop ptrI ]
                  }
            )
