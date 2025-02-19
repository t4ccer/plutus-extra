{-# LANGUAGE Trustworthy #-}

{- |
 Module: Test.Tasty.Plutus.WithScript
 Copyright: (C) MLabs 2021
 License: Apache 2.0
 Maintainer: Koz Ross <koz@mlabs.city>
 Portability: GHC only
 Stability: Experimental
-}
module Test.Tasty.Plutus.WithScript (
  -- * Environment monad
  WithScript,

  -- * Helper functions
  withValidator,
  withMintingPolicy,
  toTestValidator,
  toTestMintingPolicy,
) where

import Control.Monad.RWS.Strict (evalRWS)
import Data.Kind (Type)
import GHC.Exts (toList)
import Ledger.Typed.Scripts (
  DatumType,
  RedeemerType,
  TypedValidator,
  validatorScript,
 )
import Plutus.V1.Ledger.Scripts (MintingPolicy)
import PlutusTx.Builtins (BuiltinData, BuiltinString, appendString, trace)
import PlutusTx.IsData.Class (FromData (fromBuiltinData))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.Plutus.Internal.Context (
  Purpose (ForMinting, ForSpending),
 )
import Test.Tasty.Plutus.Internal.WithScript (
  WithScript (WithMinting, WithSpending),
 )
import Prelude

{- | Given the name for the tests, a 'Validator', and a collection of
 spending-related tests, execute all of them as a 'TestTree'.

 = Usage

 > myTests :: TestTree
 > myTests = withValidator "Testing my spending" myValidator $ do
 >    shouldValidate "Valid case" validData validContext
 >    shouldn'tValidate "Invalid context" validData invalidContext
 >    shouldn'tValidate "Invalid data" invalidData validContext
 >    shouldn'tValidate "Everything is bad" invalidData invalidContext
 >    shouldValidateTracing "Gotta get good messages" tracePred validData validContext
 >    shouldn'tValidateTracing "Oh damn" tracePred invalidData validContext
 >    scriptProperty "Some property" myGenerator mkContext
 >    ...

 = Important note

 Unless your 'Validator' has been prepared using 'toTestValidator', this will
 likely not behave as intended.

 @since 3.0
-}
withValidator ::
  forall (s :: Type).
  String ->
  TypedValidator s ->
  WithScript ( 'ForSpending (DatumType s) (RedeemerType s)) () ->
  TestTree
withValidator name val (WithSpending comp) =
  case evalRWS comp (validatorScript val) () of
    ((), tests) -> testGroup name . toList $ tests

{- | Given the name for the tests, a 'MintingPolicy', and a collection of
 minting-related tests, execute all of them as a 'TestTree'.

 = Usage

 > myTests :: TestTree
 > myTests = withMintingPolicy "Testing my minting" mp $ do
 >    shouldValidate "Valid case" validData validContext
 >    shouldn'tValidate "Invalid context" validData invalidContext
 >    shouldn'tValidate "Invalid data" invalidData validContext
 >    shouldn'tValidate "Everything is bad" invalidData invalidContext
 >    scriptProperty "Some property" myGenerator mkContext
 >    ...

 = Important note

 Unless your 'MintingPolicy' has been prepared using 'toTestMintingPolicy',
 this will likely not behave as intended.

 @since 3.0
-}
withMintingPolicy ::
  forall (r :: Type).
  String ->
  MintingPolicy ->
  WithScript ( 'ForMinting r) () ->
  TestTree
withMintingPolicy name mp (WithMinting comp) =
  case evalRWS comp mp () of
    ((), tests) -> testGroup name . toList $ tests

{- | A wrapper for validators. Use this to construct 'Validator's suitable for
 passing to 'withValidator'.

 = Usage

 > data TestScript

 > instance ValidatorTypes TestScript where
 >   type RedeemerType TestScript = SomeType
 >   type DatumType TestScript = SomeOtherType

typedSimpleValidator :: TypedValidator TestScript

 > testValidator :: TypedValidator TestScript
 > testValidator =
 >  mkTypedValidator @TestScript
 >    $$(compile [||myValidator||])
 >    $$(compile [||wrap||])
 >    where
 >      wrap ::
 >        ( SomeType -> SomeOtherType -> ScriptContext -> Bool) ->
 >        WrappedValidatorType
 >      wrap = toTestValidator

 = Important note

 If @myValidator@ requires \'burned in\' arguments, these should be passed via
 'liftCode' and 'applyCode', rather than as literal arguments inside of
 'compile':

 > testValidatorWithArg :: ArgumentType -> Validator
 > testValidatorWithArg arg =
 >  mkTypedValidator @TestScript
 >    ( $$(compile [||myValidator||])
 >          `applyCode`
 >          liftCode arg
 >    )
 >    $$(compile [||wrap||])
 >    where
 >      wrap ::
 >        ( SomeType -> SomeOtherType -> ScriptContext -> Bool) ->
 >        WrappedValidatorType
 >      wrap = toTestValidator

 @since 3.0
-}
{-# INLINEABLE toTestValidator #-}
toTestValidator ::
  forall (datum :: Type) (redeemer :: Type) (ctx :: Type).
  (FromData datum, FromData redeemer, FromData ctx) =>
  (datum -> redeemer -> ctx -> Bool) ->
  (BuiltinData -> BuiltinData -> BuiltinData -> ())
toTestValidator f d r p = case fromBuiltinData d of
  Nothing -> reportParseFailed "Datum"
  Just d' -> case fromBuiltinData r of
    Nothing -> reportParseFailed "Redeemer"
    Just r' -> case fromBuiltinData p of
      Nothing -> reportParseFailed "ScriptContext"
      Just p' ->
        if f d' r' p'
          then reportPass
          else reportFail

{- | A wrapper for minting policies. Use this to construct a 'MintingPolicy'
 suitable for passing to 'withMintingPolicy'.

 The usage (and caveats) of this function is similar to 'toTestValidator'; see
 its documentation for details.

 @since 3.0
-}
{-# INLINEABLE toTestMintingPolicy #-}
toTestMintingPolicy ::
  forall (redeemer :: Type) (ctx :: Type).
  (FromData redeemer, FromData ctx) =>
  (redeemer -> ctx -> Bool) ->
  (BuiltinData -> BuiltinData -> ())
toTestMintingPolicy f r p = case fromBuiltinData r of
  Nothing -> reportParseFailed "Redeemer"
  Just r' -> case fromBuiltinData p of
    Nothing -> reportParseFailed "ScriptContext"
    Just p' ->
      if f r' p'
        then reportPass
        else reportFail

-- Helpers

{-# INLINEABLE reportParseFailed #-}
reportParseFailed :: BuiltinString -> ()
reportParseFailed what = report ("Parse failed: " `appendString` what)

{-# INLINEABLE reportPass #-}
reportPass :: ()
reportPass = report "Pass"

{-# INLINEABLE reportFail #-}
reportFail :: ()
reportFail = report "Fail"

{-# INLINEABLE report #-}
report :: BuiltinString -> ()
report what = trace ("tasty-plutus: " `appendString` what) ()
