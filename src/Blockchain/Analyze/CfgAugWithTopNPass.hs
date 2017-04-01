{-# LANGUAGE OverloadedStrings, FlexibleContexts,
  FlexibleInstances, GADTs, Rank2Types, DeriveGeneric, TypeFamilies,
  UndecidableInstances #-}

module Blockchain.Analyze.CfgAugWithTopNPass
  ( doCfgAugWithTopNPass
  ) where

import Blockchain.Analyze
import Blockchain.Analyze.Common
import Blockchain.ExtWord
import Blockchain.VM.Opcodes as BVO
import Compiler.Hoopl
import Data.Bits as Db
import Data.ByteString as DB
import Data.List as DL
import Data.List.Extra
import Data.Maybe as DM
import Data.Set as DS
import Data.Word

type StackElemFact = WithTop (Set Word256)

joinStackElemBase
  :: Label
  -> OldFact (Set Word256)
  -> NewFact (Set Word256)
  -> (ChangeFlag, (Set Word256))
joinStackElemBase _ (OldFact oldF) (NewFact newF) =
  if newF `isSubsetOf` oldF
    then (NoChange, oldF)
    else (SomeChange, oldF `DS.union` newF)

joinStackElemFact
  :: Label
  -> OldFact StackElemFact
  -> NewFact StackElemFact
  -> (ChangeFlag, StackElemFact)
joinStackElemFact = liftJoinTop joinStackElemBase

type StackNFact = [StackElemFact]

joinStackNFact :: Label
               -> OldFact StackNFact
               -> NewFact StackNFact
               -> (ChangeFlag, StackNFact)
joinStackNFact l (OldFact oldF) (NewFact newF) =
  let zipped =
        DL.zipWith (\a b -> joinStackElemFact l (OldFact a) (NewFact b)) oldF newF
      (changedL, joinedF) = DL.unzip zipped
  in ( changeIf $
       DL.any
         (\c ->
             case c of
               SomeChange -> True
               NoChange -> False)
         changedL
     , joinedF)

stackNLattice :: Int -> DataflowLattice StackNFact
stackNLattice depth =
  DataflowLattice
  { fact_name = "stackNLattice"
  , fact_bot = DL.replicate depth (PElem DS.empty)
  , fact_join = joinStackNFact
  }

_sizeBound :: Int
_sizeBound = 10

mkTopList l = DL.map (const Top) l

pairCompute :: (Word256 -> Word256 -> Word256) -> StackNFact -> StackNFact
pairCompute fun flist =
  if DL.length flist < 2
    then mkTopList flist
    else case flist of
           Top:_:tl -> (Top : tl) ++ [Top]
           _:Top:tl -> (Top : tl) ++ [Top]
           PElem st1:PElem st2:tl ->
             let l1 = toList st1
             in ((PElem $ DS.unions $ DL.map (\e1 -> DS.map (fun e1) st2) l1) :
                 tl) ++
                [Top]

popStack :: Int -> StackNFact -> StackNFact
popStack 0 f = f
popStack n (h:t) = popStack (n - 1) (t ++ [Top])

pushStack' :: StackElemFact -> StackNFact -> StackNFact
pushStack' e flist = e : (dropEnd 1 flist)

pushStack :: Word256 -> StackNFact -> StackNFact
pushStack wd flist = pushStack' (PElem $ DS.singleton wd) flist

pushTop :: StackNFact -> StackNFact
pushTop flist = Top : (dropEnd 1 flist)

b2w256 :: Bool -> Word256
b2w256 True = 1
b2w256 False = 0

w256Not :: Word256 -> Word256
w256Not wd = bytesToWord256 $ DL.map complement $ word256ToBytes wd

w256And :: Word256 -> Word256 -> Word256
w256And wd1 wd2 =
  bytesToWord256 $ DL.zipWith (.&.) (word256ToBytes wd1) (word256ToBytes wd2)

w256Or :: Word256 -> Word256 -> Word256
w256Or wd1 wd2 =
  bytesToWord256 $ DL.zipWith (.|.) (word256ToBytes wd1) (word256ToBytes wd2)

w256Xor :: Word256 -> Word256 -> Word256
w256Xor wd1 wd2 =
  bytesToWord256 $ DL.zipWith Db.xor (word256ToBytes wd1) (word256ToBytes wd2)

peekStack :: Int -> StackNFact -> StackElemFact
peekStack _ [] = Top
peekStack 1 (h:t) = h
peekStack n (h:t) = peekStack (n - 1) t

swapStack :: Int -> StackNFact -> StackNFact
swapStack n stk =
  if n + 1 > DL.length stk
    then pushTop $ popStack 1 stk
    else let (h1:t1, h2:t2) = DL.splitAt n stk
         in (h2 : t1) ++ (h1 : t2)

stackNTransfer :: FwdTransfer HplOp StackNFact
stackNTransfer = mkFTransfer3 coT ooT ocT
  where
    coT :: HplOp C O -> StackNFact -> StackNFact
    coT _ flist =
      DL.map
        (\f ->
            case f of
              Top -> Top
              PElem st ->
                if DS.size st > _sizeBound
                  then Top
                  else PElem st)
        flist
    ooT :: HplOp O O -> StackNFact -> StackNFact
    ooT (OoOp (_, op)) f = opT op f
    ocT :: HplOp O C -> StackNFact -> FactBase StackNFact
    ocT (OcOp (_, CODECOPY) (hL:tL)) f =
      mapFromList
        ([(hL, opT CODECOPY f)] ++
         DL.map (\l -> (l, fact_bot $ fp_lattice $ cfgAugWithTopNPass)) tL)
    -- TODO(zchn): Implement JUMPI narrowing
    ocT hplop@(OcOp (_, op) _) f = distributeFact hplop (opT op f)
    opT :: Operation -> StackNFact -> StackNFact
    opT STOP flist = flist
    opT ADD flist = pairCompute (+) flist
    opT MUL flist = pairCompute (*) flist
    opT SUB flist = pairCompute (-) flist
    -- TODO(zchn): handle DIVs and MODs
    opT DIV flist = popStack 2 flist
    opT SDIV flist = popStack 2 flist
    opT MOD flist = pairCompute mod flist
    opT SMOD flist = popStack 2 flist
    -- TODO(zchn): is this right?
    opT ADDMOD flist = pairCompute (+) flist
    opT MULMOD flist = pairCompute (*) flist
    opT EXP flist = popStack 2 flist
    opT SIGNEXTEND flist = popStack 2 flist
    opT NEG flist = opT SUB $ pushStack 0 flist
    opT BVO.LT flist = pairCompute (\a b -> b2w256 $ a < b) flist
    opT BVO.GT flist = pairCompute (\a b -> b2w256 $ a > b) flist
    -- TODO(zchn): is this right?
    opT SLT flist = pairCompute (\a b -> b2w256 $ a < b) flist
    opT SGT flist = pairCompute (\a b -> b2w256 $ a > b) flist
    opT BVO.EQ flist = pairCompute (\a b -> b2w256 $ a == b) flist
    opT ISZERO flist = opT BVO.EQ $ pushStack 0 flist
    opT NOT flist = opT BVO.EQ $ pushStack 0 flist
    opT AND flist = pairCompute w256And flist
    opT OR flist = pairCompute w256Or flist
    opT XOR flist = pairCompute w256Xor flist
    opT BYTE flist = pushTop $ popStack 2 flist
    opT SHA3 flist = pushTop $ popStack 2 flist
    opT ADDRESS f = pushTop f
    opT BALANCE f = pushTop f
    opT ORIGIN f = pushTop f
    opT CALLER f = pushTop f
    opT CALLVALUE f = pushTop f
    opT CALLDATALOAD f = pushTop $ popStack 1 f
    opT CALLDATASIZE f = pushTop f
    opT CALLDATACOPY f = popStack 3 f
    opT CODESIZE f = pushTop f
    opT CODECOPY f = popStack 3 f
    opT GASPRICE f = pushTop f
    opT EXTCODESIZE f = pushTop f
    opT EXTCODECOPY f = pushTop $ pushTop $ pushTop $ pushTop f
    opT BLOCKHASH f = pushTop f
    opT COINBASE f = pushTop f
    opT TIMESTAMP f = pushTop f
    opT NUMBER f = pushTop f
    opT DIFFICULTY f = pushTop f
    opT GASLIMIT f = pushTop f
    opT POP f = popStack 1 f
    opT MLOAD f = pushTop $ popStack 1 f
    opT MSTORE f = popStack 2 f
    opT MSTORE8 f = popStack 2 f
    opT SLOAD f = pushTop $ popStack 1 f
    opT SSTORE f = popStack 2 f
    opT JUMP f = popStack 1 f
    opT JUMPI f = popStack 2 f
    opT PC f = pushTop f
    opT MSIZE f = pushTop f
    opT GAS f = pushTop f
    opT JUMPDEST flist = flist
    opT (PUSH wl) flist = pushStack (varBytesToWord256 wl) flist
    opT DUP1 flist = pushStack' (peekStack 1 flist) flist
    opT DUP2 flist = pushStack' (peekStack 2 flist) flist
    opT DUP3 flist = pushStack' (peekStack 3 flist) flist
    opT DUP4 flist = pushStack' (peekStack 4 flist) flist
    opT DUP5 flist = pushStack' (peekStack 5 flist) flist
    opT DUP6 flist = pushStack' (peekStack 6 flist) flist
    opT DUP7 flist = pushStack' (peekStack 7 flist) flist
    opT DUP8 flist = pushStack' (peekStack 8 flist) flist
    opT DUP9 flist = pushStack' (peekStack 9 flist) flist
    opT DUP10 flist = pushStack' (peekStack 10 flist) flist
    opT DUP11 flist = pushStack' (peekStack 11 flist) flist
    opT DUP12 flist = pushStack' (peekStack 12 flist) flist
    opT DUP13 flist = pushStack' (peekStack 13 flist) flist
    opT DUP14 flist = pushStack' (peekStack 14 flist) flist
    opT DUP15 flist = pushStack' (peekStack 15 flist) flist
    opT DUP16 flist = pushStack' (peekStack 16 flist) flist
    opT SWAP1 flist = swapStack 1 flist
    opT SWAP2 flist = swapStack 2 flist
    opT SWAP3 flist = swapStack 3 flist
    opT SWAP4 flist = swapStack 4 flist
    opT SWAP5 flist = swapStack 5 flist
    opT SWAP6 flist = swapStack 6 flist
    opT SWAP7 flist = swapStack 7 flist
    opT SWAP8 flist = swapStack 8 flist
    opT SWAP9 flist = swapStack 9 flist
    opT SWAP10 flist = swapStack 10 flist
    opT SWAP11 flist = swapStack 11 flist
    opT SWAP12 flist = swapStack 12 flist
    opT SWAP13 flist = swapStack 13 flist
    opT SWAP14 flist = swapStack 14 flist
    opT SWAP15 flist = swapStack 15 flist
    opT SWAP16 flist = swapStack 16 flist
    opT LOG0 flist = popStack 2 flist
    opT LOG1 flist = popStack 3 flist
    opT LOG2 flist = popStack 4 flist
    opT LOG3 flist = popStack 5 flist
    opT LOG4 flist = popStack 6 flist
    opT CREATE flist = flist
    opT CALL flist = pushTop $ popStack 7 flist
    opT CALLCODE flist = pushTop $ popStack 7 flist
    opT RETURN flist = popStack 2 flist
    opT DELEGATECALL flist = pushTop $ popStack 7 flist
    opT SUICIDE flist = popStack 1 flist
    -- opT LABEL String flist = flist
    -- opT PUSHLABEL String flist = flist
    -- opT PUSHDIFF String String flist = flist
    -- opT DATA ByteString flist = flist
    -- opT MalformedOpcode Word8 flist = flist
    opT op@LABEL {} _ = error $ "Unexpected(stackTopTransfer): " ++ show op
    opT op@PUSHLABEL {} _ = error $ "Unexpected(stackTopTransfer): " ++ show op
    opT op@PUSHDIFF {} _ = error $ "Unexpected(stackTopTransfer): " ++ show op
    opT op@DATA {} _ = error $ "Unexpected(stackTopTransfer): " ++ show op
    opT op@MalformedOpcode {} _ =
      error $ "Unexpected(stackTopTransfer): " ++ show op
    -- TODO(zchn): Implement interp
    opT _ flist = DL.map (const Top) flist

opGUnit :: HplOp e x -> Graph HplOp e x
opGUnit co@CoOp {} = gUnitCO $ BlockCO co BNil
opGUnit oo@OoOp {} = gUnitOO $ BMiddle oo
opGUnit oc@OcOp {} = gUnitOC $ BlockOC BNil oc

catPElems :: [Pointed e x t] -> [t]
catPElems plist = DM.catMaybes (DL.map maybePElem plist)
  where
    maybePElem (PElem v) = Just v
    maybePElem _ = Nothing

cfgAugWithTopNRewrite :: FwdRewrite WordLabelMapFuelM HplOp StackNFact
cfgAugWithTopNRewrite = mkFRewrite3 coR ooR ocR
  where
    coR :: HplOp C O
        -> StackNFact
        -> WordLabelMapFuelM (Maybe (Graph HplOp C O))
    coR op _ = return $ Just $ opGUnit op
    ooR :: HplOp O O
        -> StackNFact
        -> WordLabelMapFuelM (Maybe (Graph HplOp O O))
    ooR op _ = return $ Just $ opGUnit op
    ocR :: HplOp O C
        -> StackNFact
        -> WordLabelMapFuelM (Maybe (Graph HplOp O C))
    ocR op@(OcOp (loc, ope) ll) f =
      case ope of
        JUMP -> handleJmp 0
        JUMPI -> handleJmp 0
        CODECOPY -> handleJmp 1
        _ -> return $ Just $ opGUnit op
      where
        handleJmp :: Int -> WordLabelMapFuelM (Maybe (Graph HplOp O C))
        handleJmp opIdx =
          case f !! opIdx of
            Top -> return $ Just $ opGUnit op -- TODO(zchn): Should return all targets
            PElem st -> do
              newll <- liftFuel $ labelsFor $ toList st
              return $
                Just $
                opGUnit $ OcOp (loc, ope) $ toList $ fromList (ll ++ newll)

_depthBound :: Int
_depthBound = 16

cfgAugWithTopNPass :: FwdPass WordLabelMapFuelM HplOp StackNFact
cfgAugWithTopNPass =
  FwdPass
  { fp_lattice = stackNLattice _depthBound
  , fp_transfer = stackNTransfer
  , fp_rewrite = cfgAugWithTopNRewrite
  }

doCfgAugWithTopNPass :: HplContract -> WordLabelMapM HplContract
doCfgAugWithTopNPass contract =
  let entry_ = entryOf $ ctorOf contract
      body = bodyOf $ ctorOf contract
  in case entry_ of
       Nothing -> return contract
       Just entry -> do
         newBody <-
           runWithFuel
             10000000000
             (fst <$>
              analyzeAndRewriteFwdBody
                cfgAugWithTopNPass
                entry
                body
                (mapSingleton entry $ fact_bot $ fp_lattice $ cfgAugWithTopNPass))
         return
           contract
           { ctorOf = HplCode (Just entry) body
           }
