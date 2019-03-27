{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}
{-# LANGUAGE FlexibleInstances #-}

module Domains.IntervalDomain where

import Interfaces.AbstractStateDomain
import Interfaces.AbstractValueDomain
import Interfaces.CompleteLattice
import Interfaces.State
import Semantic.Atomic
import Semantic.Evaluation
import SyntacticStructure.WhileGrammar

--------------------------------------------------------------------------------
--                             Sign Domain
--------------------------------------------------------------------------------

data IntervalValue = PositiveInf
                   | N I 
                   | NegativeInf
                   deriving (Show, Read, Eq, Ord)

data IntervalDomain = Interval IntervalValue IntervalValue
                    | BottomInterval
                    deriving (Show, Read, Eq, Ord)

instance CompleteLattice IntervalDomain where

    subset BottomInterval _ = True
    subset _ BottomInterval = False
    subset (Interval a b) (Interval c d) = (a >= c) && (b <= d)

    top = Interval NegativeInf PositiveInf
    
    bottom = BottomInterval

    join BottomInterval x = x
    join x BottomInterval = x
    join (Interval a b) (Interval c d) = Interval (min a c) (max b d)

    meet BottomInterval _ = BottomInterval
    meet _ BottomInterval = BottomInterval
    meet (Interval a b) (Interval c d) 
        | (max a c) <= (min b d) = Interval (max a c) (min b d)
        | otherwise = BottomInterval
    
    widen BottomInterval x = x
    widen x BottomInterval = x
    widen (Interval a b) (Interval c d) = (Interval leftBound rightBound)
        where leftBound  = if a <= c then a else NegativeInf
              rightBound = if b >= d then b else PositiveInf

instance AVD IntervalDomain where

    cons c = Interval (N c) (N c)

    rand c1 c2 = Interval (convertToIntervalNumber c1) (convertToIntervalNumber c2)

    unary Neg BottomInterval = BottomInterval
    unary Neg (Interval a b) = Interval (invert b) (invert a)

    binary _ _ _ = BottomInterval

instance ASD IntervalStateDomain where
    cond _ _ = Bottom
    -- assign :: AtomicAssign -> SD b -> SD b
    assign _ Bottom                  = Bottom
    assign (AtomicAssign var exp) x
        | isBottom $ abstractEval exp x = Bottom
        | otherwise                     = update var (abstractEval exp x) x


type IntervalStateDomain = SD Var IntervalDomain


convertToIntervalNumber :: SignedInfiniteInteger -> IntervalValue
convertToIntervalNumber (Positive x) = N x
convertToIntervalNumber (Negative x) = N (-x)
convertToIntervalNumber PosInf = PositiveInf
convertToIntervalNumber NegInf = NegativeInf

invert :: IntervalValue -> IntervalValue
invert PositiveInf = NegativeInf
invert NegativeInf = PositiveInf
invert (N x) = N (-x)
