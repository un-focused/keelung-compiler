{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Test.Optimization.UInt (tests, run) where

import Control.Monad (forM_)
import Keelung hiding (compileO0)
import Test.Hspec
import Test.Optimization.Util

-- import Keelung.Compiler.Linker

run :: IO ()
run = hspec tests

tests :: SpecWith ()
tests = do
  describe "UInt" $ do
    describe "Variable management" $ do
      -- can be lower
      it "keelung Issue #17" $ do
        (cs, cs') <- executeGF181 $ do
          a <- input Private :: Comp (UInt 5)
          b <- input Private
          c <- reuse $ a * b
          return $ c .&. 5
        -- debug cs'
        cs `shouldHaveSize` 41
        cs' `shouldHaveSize` 41

    describe "Addition / Subtraction" $ do
      it "2 variables" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Public
          return $ x + y
        cs `shouldHaveSize` 14
        cs' `shouldHaveSize` 14

      it "1 variable + 1 constant" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          return $ x + 4
        cs `shouldHaveSize` 10
        cs' `shouldHaveSize` 10

      it "3 variable + 1 constant" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Public
          z <- inputUInt @4 Public
          return $ x + y + z + 4
        -- cs `shouldHaveSize` 19
        -- cs' `shouldHaveSize` 19
        cs `shouldHaveSize` 30
        cs' `shouldHaveSize` 30

      it "3 variable + 1 constant (with subtraction)" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Public
          z <- inputUInt @4 Public
          return $ x - y + z + 4
        -- print $ linkConstraintModule cs'
        -- cs `shouldHaveSize` 19
        -- cs' `shouldHaveSize` 19
        cs `shouldHaveSize` 30
        cs' `shouldHaveSize` 30

      -- TODO: should've been just 4
      it "2 constants" $ do
        (cs, cs') <- executeGF181 $ do
          return $ 2 + (4 :: UInt 4)
        cs `shouldHaveSize` 8
        cs' `shouldHaveSize` 8

    describe "Multiplication" $ do
      -- TODO: can be lower
      it "variable / variable" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Public
          return $ x * y
        cs `shouldHaveSize` 25
        cs' `shouldHaveSize` 25

      -- TODO: can be lower
      it "variable / constant" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          return $ x * 4
        cs `shouldHaveSize` 21
        cs' `shouldHaveSize` 21

      -- TODO: should've been just 4
      it "constant / constant" $ do
        (cs, cs') <- executeGF181 $ do
          return $ 2 * (4 :: UInt 4)
        -- print $ linkConstraintModule cs'
        cs `shouldHaveSize` 8
        cs' `shouldHaveSize` 8

    describe "Constants" $ do
      -- TODO: should be just 4
      it "`return 0`" $ do
        (cs, cs') <- executeGF181 $ do
          return (0 :: UInt 4)
        -- print $ linkConstraintModule cs'
        cs `shouldHaveSize` 8
        cs' `shouldHaveSize` 8

    describe "Comparison computation" $ do
      it "x ≤ y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          return $ x `lte` y
        cs `shouldHaveSize` 17
        cs' `shouldHaveSize` 16

      it "0 ≤ x" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          return $ (0 :: UInt 4) `lte` x
        cs `shouldHaveSize` 6
        cs' `shouldHaveSize` 6

      it "1 ≤ x" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          return $ (1 :: UInt 4) `lte` x
        cs `shouldHaveSize` 9
        cs' `shouldHaveSize` 8

      it "x ≤ 0" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          return $ x `lte` (0 :: UInt 4)
        cs `shouldHaveSize` 10
        cs' `shouldHaveSize` 8

      it "x ≤ 1" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          return $ x `lte` (1 :: UInt 4)
        cs `shouldHaveSize` 9
        cs' `shouldHaveSize` 7

      it "0 ≤ 0" $ do
        (cs, cs') <- executeGF181 $ do
          return $ 0 `lte` (0 :: UInt 4)
        cs `shouldHaveSize` 2
        cs' `shouldHaveSize` 2

      it "x < y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          return $ x `lt` y
        cs `shouldHaveSize` 17
        cs' `shouldHaveSize` 16

      it "x ≥ y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          return $ x `gte` y
        cs `shouldHaveSize` 17
        cs' `shouldHaveSize` 16

      it "x > y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          return $ x `gt` y
        cs `shouldHaveSize` 17
        cs' `shouldHaveSize` 16

    describe "Comparison assertion" $ do
      describe "between variables" $ do
        it "x ≤ y" $ do
          (cs, cs') <- executeGF181 $ do
            x <- inputUInt @4 Public
            y <- inputUInt @4 Private
            assert $ x `lte` y
          cs `shouldHaveSize` 16
          cs' `shouldHaveSize` 15

      it "x < y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          assert $ x `lt` y
        cs `shouldHaveSize` 16
        cs' `shouldHaveSize` 15

      it "x ≥ y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          assert $ x `gte` y
        cs `shouldHaveSize` 16
        cs' `shouldHaveSize` 15

      it "x > y" $ do
        (cs, cs') <- executeGF181 $ do
          x <- inputUInt @4 Public
          y <- inputUInt @4 Private
          assert $ x `gt` y
        cs `shouldHaveSize` 16
        cs' `shouldHaveSize` 15

      describe "GTE on constants (4 bits / GF181)" $ do
        let program bound = do
              x <- inputUInt @4 Public
              assert $ x `gte` (bound :: UInt 4)
        forM_
          [ (1, 5), -- special case: the number is non-zero
            (2, 6), -- trailing zero: 1
            (3, 7),
            (4, 5), -- trailing zero: 2
            (5, 7),
            (6, 6), -- trailing zero: 1
            (7, 7),
            (8, 5), -- trailing zero: 3
            (9, 7),
            (10, 6), -- trailing zero: 1
            (11, 7),
            (12, 6), -- trailing zero: 2
            (13, 6), -- special case: only 3 possible values
            (14, 5), -- special case: only 2 possible values
            (15, 8) -- special case: only 1 possible value
          ]
          $ \(bound, expectedSize) -> do
            it ("x ≥ " <> show bound) $ do
              (_, cs) <- executeGF181 (program bound)
              cs `shouldHaveSize` expectedSize

      describe "GTE on constants (4 bits / Prime 2)" $ do
        let program bound = do
              x <- inputUInt @4 Public
              assert $ x `gte` (bound :: UInt 4)
        forM_
          [ (1, 7), -- special case: the number is non-zero
            (2, 6), -- trailing zero: 1
            (3, 7),
            (4, 5), -- trailing zero: 2
            (5, 7),
            (6, 6), -- trailing zero: 1
            (7, 7),
            (8, 5), -- trailing zero: 3
            (9, 7),
            (10, 6), -- trailing zero: 1
            (11, 7),
            (12, 6), -- trailing zero: 2
            (13, 7), -- special case: only 3 possible values
            (14, 8), -- special case: only 2 possible values
            (15, 8) -- special case: only 1 possible value
          ]
          $ \(bound, expectedSize) -> do
            it ("x ≥ " <> show bound) $ do
              (_, cs) <- executePrime 2 (program bound)
              cs `shouldHaveSize` expectedSize

      describe "GTE on constants (4 bits / Prime 5)" $ do
        let program bound = do
              x <- inputUInt @4 Public
              assert $ x `gte` (bound :: UInt 4)
        forM_
          [ (1, 5), -- special case: the number is non-zero
            (2, 6), -- trailing zero: 1
            (3, 7),
            (4, 5), -- trailing zero: 2
            (5, 7),
            (6, 6), -- trailing zero: 1
            (7, 7),
            (8, 5), -- trailing zero: 3
            (9, 7),
            (10, 6), -- trailing zero: 1
            (11, 7),
            (12, 6), -- trailing zero: 2
            (13, 8), -- special case: only 3 possible values
            (14, 7), -- special case: only 2 possible values
            (15, 8) -- special case: only 1 possible value
          ]
          $ \(bound, expectedSize) -> do
            it ("x ≥ " <> show bound) $ do
              (_, cs) <- executePrime 5 (program bound)
              cs `shouldHaveSize` expectedSize

      describe "LTE on constants (4 bits / GF181)" $ do
        let program bound = do
              x <- inputUInt @4 Public
              assert $ x `lte` (bound :: UInt 4)
        forM_
          [ (0, 8), -- special case: only 1 possible value
            (1, 5), -- special case: only 2 possible value
            (2, 6), -- special case: only 3 possible value
            (3, 6), -- trailing one: 1
            (4, 7),
            (5, 6), -- trailing one: 1
            (6, 7),
            (7, 5), -- trailing one: 2
            (5, 6),
            (9, 6), -- trailing one: 1
            (10, 7),
            (11, 5), -- trailing one: 2
            (12, 7),
            (13, 6), -- trailing one: 1
            (14, 7)
          ]
          $ \(bound, expectedSize) -> do
            it ("x ≥ " <> show bound) $ do
              (_, cs) <- executeGF181 (program bound)
              cs `shouldHaveSize` expectedSize

      describe "between constants" $ do
        it "0 ≤ 0" $ do
          (cs, cs') <- executeGF181 $ do
            assert $ 0 `lte` (0 :: UInt 4)
          cs `shouldHaveSize` 0
          cs' `shouldHaveSize` 0
