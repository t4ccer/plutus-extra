{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module NatRatio (tests) where

import Functions.NatRatio qualified as NR
import Plutus.V1.Ledger.Scripts (fromCompiledCode)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.Plutus.Size (bytes, fitsInto)
import Prelude hiding (Rational, abs, signum, (/))

tests :: [TestTree]
tests =
  [ testGroup
      "Eq"
      [ fitsInto "==" [bytes| 72 |] . fromCompiledCode $ NR.nrEq
      , fitsInto "/=" [bytes| 72 |] . fromCompiledCode $ NR.nrNeq
      ]
  , testGroup
      "Ord"
      [ fitsInto "compare" [bytes| 109 |] . fromCompiledCode $ NR.nrCompare
      , fitsInto "<=" [bytes| 62 |] . fromCompiledCode $ NR.nrLE
      , fitsInto ">=" [bytes| 62 |] . fromCompiledCode $ NR.nrGE
      , fitsInto "<" [bytes| 62 |] . fromCompiledCode $ NR.nrLT
      , fitsInto ">" [bytes| 62 |] . fromCompiledCode $ NR.nrGT
      , fitsInto "min" [bytes| 70 |] . fromCompiledCode $ NR.nrMin
      , fitsInto "max" [bytes| 70 |] . fromCompiledCode $ NR.nrMax
      ]
  , testGroup
      "AdditiveGroup"
      [ fitsInto "+" [bytes| 159 |] . fromCompiledCode $ NR.nrPlus
      , fitsInto "zero" [bytes| 24 |] . fromCompiledCode $ NR.nrZero
      , fitsInto "^-" [bytes| 183 |] . fromCompiledCode $ NR.nrMonus
      ]
  , testGroup
      "MultiplicativeGroup"
      [ fitsInto "*" [bytes| 151 |] . fromCompiledCode $ NR.nrTimes
      , fitsInto "one" [bytes| 24 |] . fromCompiledCode $ NR.nrOne
      , fitsInto "/" [bytes| 144 |] . fromCompiledCode $ NR.nrDiv
      , fitsInto "reciprocal" [bytes| 92 |] . fromCompiledCode $ NR.nrRecip
      , fitsInto "powNat" [bytes| 343 |] . fromCompiledCode $ NR.nrPowNat
      , fitsInto "powInteger" [bytes| 357 |] . fromCompiledCode $ NR.nrPowInteger
      ]
  , testGroup
      "Serialization"
      [ fitsInto "toBuiltinData" [bytes| 78 |] . fromCompiledCode $ NR.nrToBuiltinData
      , fitsInto "fromBuiltinData" [bytes| 413 |] . fromCompiledCode $ NR.nrFromBuiltinData
      , fitsInto "unsafeFromBuiltinData" [bytes| 263 |] . fromCompiledCode $ NR.nrUnsafeFromBuiltinData
      ]
  , testGroup
      "Other"
      [ fitsInto "fromNatural" [bytes| 24 |] . fromCompiledCode $ NR.nrFromNatural
      , fitsInto "numerator" [bytes| 26 |] . fromCompiledCode $ NR.nrNumerator
      , fitsInto "denominator" [bytes| 26 |] . fromCompiledCode $ NR.nrNumerator
      , fitsInto "round" [bytes| 282 |] . fromCompiledCode $ NR.nrRound
      , fitsInto "truncate" [bytes| 30 |] . fromCompiledCode $ NR.nrTruncate
      , fitsInto "properFraction" [bytes| 57 |] . fromCompiledCode $ NR.nrProperFraction
      ]
  ]
