module STMContainers.HAMT.Node.Nodes where

import STMContainers.Prelude
import qualified STMContainers.WordArray as WordArray
import qualified STMContainers.Visit as Visit


type Nodes n = WordArray.WordArray (TVar n)

type Index = WordArray.Index

type Visit n r = Visit.VisitM STM n r

visitM :: Visit n r -> Index -> Nodes n -> STM (r, Nodes n)
visitM a i = 
  inline WordArray.visitM a' i
  where
    a' = \case
      Just v -> do
        (r, c) <- a . Just =<< readTVar v
        case c of
          Visit.Keep -> return (r, Visit.Keep)
          Visit.Remove -> return (r, Visit.Remove)
          Visit.Replace n' -> writeTVar v n' >> return (r, Visit.Keep)
      Nothing -> do
        (r, c) <- a Nothing
        case c of
          Visit.Replace n' -> newTVar n' >>= \v -> return (r, Visit.Replace v)
          _ -> return (r, Visit.Keep)

foldM :: (a -> n -> STM a) -> a -> Nodes n -> STM a
foldM f = inline WordArray.foldM (\acc v -> readTVar v >>= f acc)

null :: Nodes n -> Bool
null = inline WordArray.null

fromSizedList :: (Int, [(Index, n)]) -> STM (Nodes n)
fromSizedList (size, list) = 
  inline WordArray.fromSizedListM (size, list')
  where
    list' = map (\(i, n) -> fmap (i,) (newTVar n)) list
