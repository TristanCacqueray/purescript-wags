module WAGS.Control.Types
  ( FrameT
  , Frame
  , AudioState
  , AudioState'
  , InitialUniverse
  , InitialFrameT
  , InitialFrame
  , Frame0
  , SceneT(..)
  , SceneT'
  , Scene
  , oneFrame
  , oneFrame'
  , oneFrameT
  , oneFrameT'
  , unsafeUnframe
  , unsafeFrame
  ) where

import Prelude

import Control.Apply.Indexed (class IxApply)
import Data.Functor.Indexed (class IxFunctor)
import Data.Map as M
import Data.Set (Set)
import Data.Tuple.Nested ((/\), type (/\))
import Type.Data.Peano (Z)
import Unsafe.Coerce (unsafeCoerce)
import WAGS.Control.MemoizedState (MemoizedStateT)
import WAGS.Control.Thunkable (Thunkable, runThunkable)
import WAGS.Rendered (AnAudioUnit)
import WAGS.Universe.Bin (D0)
import WAGS.Universe.Graph (InitialGraph)
import WAGS.Universe.Skolems (SkolemListNil)
import WAGS.Universe.Universe (Universe, UniverseC)

type AudioState' env audio (engine :: Type)
  = { env :: env
    , currentIdx :: Int
    , instructions :: Array (audio -> engine)
    , internalNodes :: M.Map Int (AnAudioUnit)
    , internalEdges :: M.Map Int (Set Int)
    }

type AudioState env audio engine proof m a
  = (MemoizedStateT proof (AudioState' env audio engine) m) a

newtype FrameT (env :: Type) (audio :: Type) (engine :: Type) (proof :: Type) (m :: Type -> Type) (iu :: Universe) (ou :: Universe) (a :: Type)
  = FrameT (AudioState env audio engine proof m a)

unsafeUnframe :: forall env audio engine proof m iu ou a. FrameT env audio engine proof m iu ou a -> AudioState env audio engine proof m a
unsafeUnframe (FrameT x) = x

unsafeFrame :: forall env audio engine proof m iu ou a. AudioState env audio engine proof m a -> FrameT env audio engine proof m iu ou a
unsafeFrame = FrameT

type Frame (env :: Type) (audio :: Type) (engine :: Type) (proof :: Type) (iu :: Universe) (ou :: Universe) (a :: Type)
  = FrameT env audio engine proof Thunkable iu ou a

data Frame0

type InitialUniverse
  = UniverseC D0 InitialGraph Z SkolemListNil

type InitialFrameT env audio engine m a
  = FrameT env audio engine Frame0 m InitialUniverse InitialUniverse a

type InitialFrame env audio engine a
  = Frame env audio engine Frame0 InitialUniverse InitialUniverse a

instance frameFunctor :: Monad m => Functor (FrameT env audio engine proof m i o) where
  map f (FrameT (a)) = FrameT (f <$> a)

instance frameIxFunctor :: Monad m => IxFunctor (FrameT env audio engine proof m) where
  imap f (FrameT (a)) = FrameT (f <$> a)

instance frameIxApplicative :: Monad m => IxApply (FrameT env audio engine proof m) where
  iapply (FrameT (f)) (FrameT (a)) = FrameT ((f <*> a))

data SceneT :: forall k. Type -> Type -> Type -> k -> (Type -> Type) -> Type
data SceneT env audio engine proof m
  = SceneT (env -> m (SceneT' env audio engine proof m))

type Scene :: forall k. Type -> Type -> Type ->k -> Type
type Scene env audio engine proof
  = SceneT env audio engine proof Thunkable

type SceneT' :: forall k. Type -> Type -> Type -> k -> (Type -> Type) -> Type
type SceneT' env audio engine proof m
  = { nodes :: M.Map Int AnAudioUnit
    , edges :: M.Map Int (Set Int)
    , instructions :: Array (audio -> engine)
    , next :: SceneT env audio engine proof m
    }

type Scene' :: forall k. Type -> Type -> Type -> k -> Type
type Scene' env audio engine proof
  = SceneT' env audio engine proof Thunkable

oneFrameT :: forall env audio engine proofA m. Monad m => SceneT env audio engine proofA m -> env -> (forall proofB. m (SceneT' env audio engine proofB m))
oneFrameT (SceneT f) = (unsafeCoerce :: (env -> m (SceneT' env audio engine proofA m)) -> (env -> (forall proofB. m (SceneT' env audio engine proofB m))) ) f
  

oneFrame :: forall env audio engine proofA. Scene env audio engine proofA -> env -> (forall proofB. Scene' env audio engine proofB)
oneFrame m s = runThunkable (oneFrameT m s)

oneFrameT' :: forall env audio engine proofA m. Monad m => SceneT env audio engine proofA m -> env -> (forall proofB. m (M.Map Int AnAudioUnit /\ M.Map Int (Set Int) /\ Array (audio -> engine) /\ SceneT env audio engine proofB m))
oneFrameT' s e = go <$> (oneFrameT s e)
  where
  go x = nodes /\ edges /\ instructions /\ next
    where
    { nodes, edges, instructions, next } = x

oneFrame' :: forall env audio engine proofA. Scene env audio engine proofA -> env -> (forall proofB. (M.Map Int AnAudioUnit /\ M.Map Int (Set Int) /\ Array (audio -> engine) /\ Scene env audio engine proofB))
oneFrame' s e = runThunkable (oneFrameT' s e)
