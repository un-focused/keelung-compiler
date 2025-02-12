module Keelung.Compiler.Compile.IndexTable (IndexTable, empty, fromOccurrenceMap, reindex, merge) where

import Data.IntMap.Strict (IntMap)
import Data.IntMap.Strict qualified as IntMap
import Keelung (Width)

-------------------------------------------------------------------------------

-- | Lookup table for speeding up variable renumbering:
--   Some of the variables maybe unused, we want to remove unused variables and renumber the remaining variables so that they are contiguous.
--   To do so, we create a lookup table that keep tracks of "hole" sections in the domain.
--
--   Suppose we have 10 variables, but only some of them are used:
--
--                      0 1 2 3 4 5 6 7 8 9
--   used               x x     x x x     x
--
--                              ^         ^
--   unused so far              2         4
--
--   table: [(4, 2), (9, 4)]
--
--   we want to mark the place where the used variable segments begins, so that we can know how many unused variables are there so far.
--   So that when we want to renumber the 6th variable, we can just minus 2 from it
data IndexTable = IndexTable
  { indexTableDomainSize :: Int,
    indexTableTotalUsedVarsSize :: Int,
    indexTable :: IntMap Int
  }
  deriving (Show)

data FoldState = FoldState
  { -- | The resulting table
    _stateTable :: IntMap Int,
    -- | The last variable that is used
    _stateLasUsedVar :: Maybe Int,
    -- | The number of used variables so far
    _stateTotalUsedVarsSize :: Int
  }

instance Semigroup IndexTable where
  (<>) = merge

instance Monoid IndexTable where
  mempty = empty

-- | O(1). Construct an empty IndexTable
empty :: IndexTable
empty = IndexTable 0 0 mempty

-- | O( size of the occurence map ). Construct an IndexTable from an ocurence map
fromOccurrenceMap :: Width -> (Int, IntMap Int) -> IndexTable
fromOccurrenceMap width (domainSize, occurrences) =
  let FoldState xs _ totalUsedSize = IntMap.foldlWithKey' go (FoldState mempty Nothing 0) occurrences
   in IndexTable (width * domainSize) totalUsedSize xs
  where
    go :: FoldState -> Int -> Int -> FoldState
    go (FoldState acc lastUsedVar totalUsedSize) _ 0 = FoldState acc lastUsedVar totalUsedSize -- skip unused variables
    go (FoldState acc Nothing totalUsedSize) var _ = FoldState (IntMap.insert (width * var) (width * var - width * totalUsedSize) acc) (Just var) (totalUsedSize + width) -- encounted the first used variable
    go (FoldState acc (Just lastVar) totalUsedSize) var _ = 
      let skippedDistance = width * (var - lastVar - 1)
       in if skippedDistance > 0
            then FoldState (IntMap.insert (width * var) (width * var - totalUsedSize) acc) (Just var) (totalUsedSize + width) -- skipped a hole
            else FoldState acc (Just var) (totalUsedSize + width) -- no hole skipped

-- let FoldState xs _ _ totalHoleSize startsWithHole = IntMap.foldlWithKey' go (FoldState mempty False Nothing 0 Nothing) occurrences
--  in IndexTable (width * domainSize) totalHoleSize startsWithHole xs
-- where
--   skippedSomeVars :: Int -> Maybe Int -> Bool
--   skippedSomeVars _ Nothing = False
--   skippedSomeVars var (Just var') = var - var' > 1

--   go :: FoldState -> Int -> Int -> FoldState
--   go (FoldState acc False lastUsedVar totalHoleSize Nothing) var count =
--     case lastUsedVar of
--       Nothing ->
--         if count == 0
--           then FoldState acc True Nothing (totalHoleSize + width) (Just True) -- staring a new hole
--           else FoldState acc False _ totalHoleSize (Just False) -- still not in a hole
--       Just var' ->
--         if count == 0
--           then FoldState acc True (Just var') (totalHoleSize + width) (Just True) -- staring a new hole
--           else
--             if var - var' > 1
--               then
--                 let skippedDistance = width * (var - var' - 1)
--                     currentTotalHoleSize = totalHoleSize + skippedDistance
--                  in FoldState (IntMap.insert (var * width) currentTotalHoleSize acc) False (Just var) currentTotalHoleSize (Just False) -- skipped a hole
--               else FoldState acc False _ totalHoleSize (Just False) -- still not in a hole
--   go (FoldState acc False lastUsedVar totalHoleSize (Just startsWithHole)) var count =
--     case lastUsedVar of
--       Nothing ->
--         if count == 0
--           then FoldState acc True _ (totalHoleSize + width) (Just startsWithHole) -- staring a new hole
--           else FoldState acc False _ totalHoleSize (Just startsWithHole) -- still not in a hole
--   go (FoldState acc True lastUsedVar totalHoleSize startsWithHole) var count =
--     if count == 0
--       then FoldState acc True _ (totalHoleSize + width) startsWithHole -- still in a hole
--       else FoldState (IntMap.insert (var * width) totalHoleSize acc) False _ totalHoleSize startsWithHole -- ending the current hole

-- | O(lg n). Given an IndexTable and a variable, reindex the variable so that it become contiguous with the other variables
reindex :: IndexTable -> Int -> Int
reindex (IndexTable _ _ xs) var = case IntMap.lookupLE var xs of
  Nothing -> var
  Just (_, vacancyCount) -> var - vacancyCount

-- | O(lg n). Mergin two IndexTable
merge :: IndexTable -> IndexTable -> IndexTable
merge (IndexTable domainSize1 totalUsedSize1 xs1) (IndexTable domainSize2 totalUsedSize2 xs2) =
  let totalUsedSize = totalUsedSize1 + totalUsedSize2
   in IndexTable (domainSize1 + domainSize2) totalUsedSize $ xs1 <> IntMap.mapKeys (+ domainSize1) (IntMap.map (\x -> x + domainSize1 - totalUsedSize1) xs2)
