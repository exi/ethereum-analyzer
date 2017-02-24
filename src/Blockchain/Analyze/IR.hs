{-# LANGUAGE OverloadedStrings, FlexibleContexts,
  FlexibleInstances, GADTs, Rank2Types, DeriveGeneric #-}

module Blockchain.Analyze.IR
  ( HplBody
  , HplOp
  , WordLabelMapM
  , unWordLabelMapM
  , evmOps2HplBody
  , labelFor
  , labelsFor
  , showOp
  , showOps
  ) where

import Blockchain.ExtWord as BE
import Blockchain.VM.Opcodes as BVO
import Compiler.Hoopl as CH
import Control.Monad as CM
import Data.Bimap as DB
import Data.Text as DT
import Legacy.Haskoin.V0102.Network.Haskoin.Crypto.BigWord

data HplOp e x where
        CoOp :: Label -> HplOp C O
        OoOp :: (Word256, Operation) -> HplOp O O
        OcOp :: (Word256, Operation) -> [Label] -> HplOp O C

showLoc :: Word256 -> String
showLoc = show . getBigWordInteger

showOp :: (Word256, Operation) -> String
showOp (lineNo, op) = showLoc lineNo ++ ": " ++ show op

showOps :: [(Word256, Operation)] -> [String]
showOps = Prelude.map showOp

instance Show (HplOp e x) where
  show (CoOp l) = "CO: " ++ show l
  show (OoOp op) = "OO: " ++ showOp op
  show (OcOp op ll) = "OC: " ++ showOp op ++ " -> " ++ show ll

instance Show (Block HplOp C C) where
  show a =
    let (h, m, t) = blockSplit a
    in show (h, blockToList m, t)

instance Eq (HplOp C O) where
  (==) (CoOp a) (CoOp b) = a == b

instance Eq (HplOp O O) where
  (==) (OoOp a) (OoOp b) = a == b

instance Eq (HplOp O C) where
  (==) (OcOp a _) (OcOp b _) = a == b

instance NonLocal HplOp where
  entryLabel (CoOp l) = l
  successors (OcOp _ ll) = ll

type HplBody = Body HplOp

-- evmOp2HplOp :: (Word256, Operation) -> WordLabelMapM (Either (HplOp O O) (HplOp O C))
-- evmOp2HplOp op@(loc, STOP) = return $ Right $ OcOp op []
-- evmOp2HplOp op = error ("Unimplemented(evmOp2HplOp):" ++ show op)
evmOps2HplBody :: [(Word256, Operation)] -> WordLabelMapM HplBody
evmOps2HplBody [] = return emptyBody
evmOps2HplBody el@((loc, _):_) = do
  l <- labelFor loc
  doEvmOps2HplBody emptyBody (blockJoinHead (CoOp l) emptyBlock) el
  where
    doEvmOps2HplBody :: HplBody
                     -> (Block HplOp C O)
                     -> [(Word256, Operation)]
                     -> WordLabelMapM HplBody
    doEvmOps2HplBody body hd [] = return body -- sliently discarding bad hds
    doEvmOps2HplBody body hd (h':[]) =
      if isTerminator (snd h')
        then return $ addBlock (blockJoinTail hd (OcOp h' [])) body
        else return body
    doEvmOps2HplBody body hd (h':(t'@((loc', _):_))) =
      if isTerminator (snd h')
        then do
          l' <- labelFor loc'
          doEvmOps2HplBody
            (addBlock
               (blockJoinTail
                  hd
                  (OcOp
                     h'
                     (if canPassThrough (snd h')
                        then [l']
                        else [])))
               body)
            (blockJoinHead (CoOp l') emptyBlock)
            t'
        else doEvmOps2HplBody body (blockSnoc hd (OoOp h')) t'

isTerminator :: Operation -> Bool
isTerminator STOP = True
isTerminator JUMP = True
isTerminator JUMPI = True
isTerminator CALL = True
isTerminator CALLCODE = True
isTerminator RETURN = True
isTerminator DELEGATECALL = True
isTerminator SUICIDE = True
isTerminator _ = False

canPassThrough :: Operation -> Bool
canPassThrough STOP = False
canPassThrough JUMP = False
canPassThrough RETURN = False
canPassThrough SUICIDE = False
canPassThrough _ = True

--------------------------------------------------------------------------------
-- The WordLabelMapM monad
--------------------------------------------------------------------------------
type WordLabelMap = Bimap Word256 Label

data WordLabelMapM a =
  WordLabelMapM (WordLabelMap -> SimpleUniqueMonad (WordLabelMap, a))

labelFor :: Word256 -> WordLabelMapM Label
labelFor word = WordLabelMapM f
  where
    f m =
      case DB.lookup word m of
        Just l' -> return (m, l')
        Nothing -> do
          l' <- freshLabel
          let m' = DB.insert word l' m
          return (m', l')

labelsFor :: [Word256] -> WordLabelMapM [Label]
labelsFor = mapM labelFor

instance Monad WordLabelMapM where
  return = pure
  WordLabelMapM f1 >>= k =
    WordLabelMapM $
    \m -> do
      (m', x) <- f1 m
      let (WordLabelMapM f2) = k x
      f2 m'

instance Functor WordLabelMapM where
  fmap = liftM

instance Applicative WordLabelMapM where
  pure x = WordLabelMapM (\m -> return (m, x))
  (<*>) = ap

class UnWordLabelMapM a  where
  unWordLabelMapM :: WordLabelMapM a -> a

instance UnWordLabelMapM Int where
  unWordLabelMapM = internalUnWordLabelMapM

instance UnWordLabelMapM String where
  unWordLabelMapM = internalUnWordLabelMapM

instance UnWordLabelMapM Text where
  unWordLabelMapM = internalUnWordLabelMapM

internalUnWordLabelMapM :: WordLabelMapM a -> a
internalUnWordLabelMapM (WordLabelMapM f) =
  snd $ runSimpleUniqueMonad (f DB.empty)
