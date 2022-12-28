{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UndecidableInstances #-}

module Test.Interpreter (tests) where

import qualified Basic
import Control.Arrow (left)
import Keelung
import Keelung.Compiler (Error (..))
import qualified Keelung.Compiler.Interpret.Kinded as Kinded
import Keelung.Compiler.Interpret.Monad hiding (Error)
import qualified Keelung.Compiler.Interpret.Typed as Typed
import qualified Keelung.Compiler.Syntax.Inputs as Inputs
import Test.Hspec
import Test.QuickCheck hiding ((.&.))

kinded :: (GaloisField n, Integral n, Encode t, FreeVar t, Interpret t n) => Comp t -> [n] -> Either (Error n) [n]
kinded prog rawInputs = do
  elab <- left LangError (elaborate' prog)
  let inps = Inputs.deserialize (compCounters (elabComp elab)) rawInputs
  left InterpretError (Kinded.run elab inps)

typed :: (GaloisField n, Integral n, Encode t) => Comp t -> [n] -> Either (Error n) [n]
typed prog rawInputs = do
  elab <- left LangError (elaborate prog)
  let inps = Inputs.deserializeElab elab rawInputs
  left InterpretError (Typed.run elab inps)

tests :: SpecWith ()
tests = do
  describe "Interpreters of different syntaxes should computes the same result" $ do
    it "Basic.identity" $
      property $ \inp -> do
        kinded Basic.identity [inp :: GF181]
          `shouldBe` Right [inp]
        typed Basic.identity [inp :: GF181]
          `shouldBe` Right [inp]

    it "Basic.add3" $
      property $ \inp -> do
        kinded Basic.add3 [inp :: GF181]
          `shouldBe` Right [inp + 3]
        typed Basic.add3 [inp :: GF181]
          `shouldBe` Right [inp + 3]

    it "Basic.eq1" $
      property $ \inp -> do
        let expectedOutput = if inp == 3 then [1] else [0]
        kinded Basic.eq1 [inp :: GF181]
          `shouldBe` Right expectedOutput
        typed Basic.eq1 [inp :: GF181]
          `shouldBe` Right expectedOutput

    it "Basic.cond'" $
      property $ \inp -> do
        let expectedOutput = if inp == 3 then [12] else [789]
        kinded Basic.cond' [inp :: GF181]
          `shouldBe` Right expectedOutput
        typed Basic.cond' [inp :: GF181]
          `shouldBe` Right expectedOutput

    it "Basic.summation" $
      forAll (vector 4) $ \inp -> do
        let expectedOutput = [sum inp]
        kinded Basic.summation (inp :: [GF181])
          `shouldBe` Right expectedOutput
        typed Basic.summation inp
          `shouldBe` Right expectedOutput

    it "Basic.summation2" $
      forAll (vector 4) $ \inp -> do
        let expectedOutput = []
        kinded Basic.summation2 (inp :: [GF181])
          `shouldBe` Right expectedOutput
        typed Basic.summation2 inp
          `shouldBe` Right expectedOutput

    it "Mixed 0" $ do
      let program = do
            f <- inputField
            u4 <- inputUInt @4
            b <- inputBool
            return $
              cond
                (b .&. (u4 !!! 0))
                (f + 1)
                (f + 2)

      kinded program [100, 1, 1 :: GF181]
        `shouldBe` Right [101]
      typed program [100, 1, 1 :: GF181]
        `shouldBe` Right [101]

      kinded program [100, 0, 1 :: GF181]
        `shouldBe` Right [102]
      typed program [100, 0, 1 :: GF181]
        `shouldBe` Right [102]

    it "Rotate" $ do
      let program = do
            x <- inputUInt @4
            return $ toArray [rotate x (-4), rotate x (-3), rotate x (-2), rotate x (-1), rotate x 0, rotate x 1, rotate x 2, rotate x 3, rotate x 4]

      kinded program [0 :: GF181]
        `shouldBe` Right [0, 0, 0, 0, 0, 0, 0, 0, 0]
      typed program [0 :: GF181]
        `shouldBe` Right [0, 0, 0, 0, 0, 0, 0, 0, 0]

      kinded program [1 :: GF181]
        `shouldBe` Right [1, 2, 4, 8, 1, 2, 4, 8, 1]
      typed program [1 :: GF181]
        `shouldBe` Right [1, 2, 4, 8, 1, 2, 4, 8, 1]

      kinded program [3 :: GF181]
        `shouldBe` Right [3, 6, 12, 9, 3, 6, 12, 9, 3]
      typed program [3 :: GF181]
        `shouldBe` Right [3, 6, 12, 9, 3, 6, 12, 9, 3]

      kinded program [5 :: GF181]
        `shouldBe` Right [5, 10, 5, 10, 5, 10, 5, 10, 5]
      typed program [5 :: GF181]
        `shouldBe` Right [5, 10, 5, 10, 5, 10, 5, 10, 5]

    it "Shift" $ do
      let program = do
            x <- inputUInt @4
            return $ toArray [shift x (-4), shift x (-3), shift x (-2), shift x (-1), shift x 0, shift x 1, shift x 2, shift x 3, shift x 4]

      kinded program [0 :: GF181]
        `shouldBe` Right [0, 0, 0, 0, 0, 0, 0, 0, 0]
      typed program [0 :: GF181]
        `shouldBe` Right [0, 0, 0, 0, 0, 0, 0, 0, 0]

      kinded program [1 :: GF181]
        `shouldBe` Right [0, 0, 0, 0, 1, 2, 4, 8, 0]
      typed program [1 :: GF181]
        `shouldBe` Right [0, 0, 0, 0, 1, 2, 4, 8, 0]

      kinded program [3 :: GF181]
        `shouldBe` Right [0, 0, 0, 1, 3, 6, 12, 8, 0]
      typed program [3 :: GF181]
        `shouldBe` Right [0, 0, 0, 1, 3, 6, 12, 8, 0]

      kinded program [5 :: GF181]
        `shouldBe` Right [0, 0, 1, 2, 5, 10, 4, 8, 0]
      typed program [5 :: GF181]
        `shouldBe` Right [0, 0, 1, 2, 5, 10, 4, 8, 0]