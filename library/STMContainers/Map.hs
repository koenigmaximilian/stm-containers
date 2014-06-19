module STMContainers.Map
(
  Map,
  Indexable,
  Association(..),
  Alter,
  Alter.Command,
  lookup,
  insert,
  delete,
  alter,
  foldM,
)
where

import STMContainers.Prelude hiding (insert, delete, lookup, alter, foldM)
import qualified STMContainers.HAMT as HAMT
import qualified STMContainers.HAMT.Node as HAMTNode
import qualified STMContainers.Alter as Alter


-- |
-- A hash table, based on an STM-specialized hash array mapped trie.
type Map k v = HAMT.HAMT (Association k v)

-- |
-- A standard constraint for keys.
type Indexable a = (Eq a, Hashable a)

-- |
-- A key-value association.
data Association k v = Association !k !v

-- |
-- A modification function for 'alter'.
type Alter a r = Maybe a -> STM (r, Alter.Command a)

instance (Eq k) => HAMTNode.Element (Association k v) where
  type ElementIndex (Association k v) = k
  elementIndex (Association k v) = k

associationValue :: Association k v -> v
associationValue (Association _ v) = v

associationToTuple :: Association k v -> (k, v)
associationToTuple (Association k v) = (k, v)

lookup :: (Indexable k) => k -> Map k v -> STM (Maybe v)
lookup k = (fmap . fmap) associationValue . inline HAMT.lookup k

insert :: (Indexable k) => k -> v -> Map k v -> STM ()
insert k v = inline HAMT.insert (Association k v)

delete :: (Indexable k) => k -> Map k v -> STM ()
delete = inline HAMT.delete

alter :: (Indexable k) => (Alter (Association k v) r) -> k -> Map k v -> STM r
alter = inline HAMT.alter

foldM :: (a -> Association k v -> STM a) -> a -> Map k v -> STM a
foldM = inline HAMT.foldM

