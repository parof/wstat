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

    cons c     = Interval (N c) (N c)

    rand c1 c2 = Interval (convertToIntervalNumber c1) (convertToIntervalNumber c2)

    unary Neg BottomInterval = BottomInterval
    unary Neg (Interval a b) = Interval (invert b) (invert a)

    binary _ BottomInterval _ = BottomInterval
    binary _ _ BottomInterval = BottomInterval
    binary Add      (Interval a b) (Interval c d) = addIntervals (a,b) (c,d)
    binary Subtract (Interval a b) (Interval c d) = subtractIntervals (a,b) (c,d)
    binary Multiply (Interval a b) (Interval c d) = multiplyIntervals (a,b) (c,d)
    binary Division (Interval a b) (Interval c d) = divideIntervals (a,b) (c,d)

    
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

addIntervals :: (IntervalValue, IntervalValue) -> (IntervalValue, IntervalValue) -> IntervalDomain
addIntervals (a, b) (c, d) = Interval (addIntervalValues a c) (addIntervalValues b d)

addIntervalValues :: IntervalValue -> IntervalValue -> IntervalValue
addIntervalValues PositiveInf NegativeInf = error "added neginf to posinf"
addIntervalValues NegativeInf PositiveInf = error "added posinf to neginf"
addIntervalValues PositiveInf _           = PositiveInf
addIntervalValues _ PositiveInf           = PositiveInf
addIntervalValues NegativeInf _           = NegativeInf
addIntervalValues _ NegativeInf           = NegativeInf
addIntervalValues (N x) (N y)             = N (x + y)

subtractIntervals :: (IntervalValue, IntervalValue) -> (IntervalValue, IntervalValue) -> IntervalDomain
subtractIntervals (a, b) (c, d) = Interval (subIntervalValues a c) (subIntervalValues b d)

subIntervalValues :: IntervalValue -> IntervalValue -> IntervalValue
subIntervalValues PositiveInf NegativeInf = error "subtracted neginf to posinf"
subIntervalValues NegativeInf PositiveInf = error "subtracted posinf to neginf"
subIntervalValues PositiveInf _           = PositiveInf
subIntervalValues _ PositiveInf           = NegativeInf
subIntervalValues NegativeInf _           = NegativeInf
subIntervalValues _ NegativeInf           = PositiveInf
subIntervalValues (N x) (N y)             = N (x - y)

multiplyIntervals :: (IntervalValue, IntervalValue) -> (IntervalValue, IntervalValue) -> IntervalDomain
multiplyIntervals (a, b) (c, d) = Interval (minimum [ac, ad, bc, bd]) (maximum [ac, ad, bc, bd])
    where ac = multIntervalValues a c
          ad = multIntervalValues a d
          bc = multIntervalValues b c
          bd = multIntervalValues b d

multIntervalValues :: IntervalValue -> IntervalValue -> IntervalValue
multIntervalValues PositiveInf NegativeInf = error "multiplied posinf with neginf"
multIntervalValues NegativeInf PositiveInf = error "multiplied neginf with posinf"
multIntervalValues PositiveInf PositiveInf = PositiveInf
multIntervalValues NegativeInf NegativeInf = PositiveInf
multIntervalValues PositiveInf (N 0)       = N 0 -- non standard, described in the notes
multIntervalValues PositiveInf (N x)       = if x > 0 then PositiveInf else NegativeInf
multIntervalValues (N 0) PositiveInf       = N 0 
multIntervalValues (N x) PositiveInf       = if x > 0 then PositiveInf else NegativeInf
multIntervalValues NegativeInf (N 0)       = N 0 
multIntervalValues NegativeInf (N x)       = if x > 0 then NegativeInf else PositiveInf
multIntervalValues (N 0) NegativeInf       = N 0 
multIntervalValues (N x) NegativeInf       = if x > 0 then NegativeInf else PositiveInf
multIntervalValues (N x) (N y)             = N (x * y)

divideIntervals :: (IntervalValue, IntervalValue) -> (IntervalValue, IntervalValue) -> IntervalDomain
divideIntervals _ (N 0, N 0) = BottomInterval

divideIntervalValues :: IntervalValue -> IntervalValue -> IntervalValue
divideIntervalValues _           (N 0)       = error "Divided an interval value by zero" -- PRE: this should never be the case
divideIntervalValues PositiveInf (N x)       = if x > 0 then PositiveInf else NegativeInf
divideIntervalValues NegativeInf (N x)       = if x > 0 then NegativeInf else PositiveInf

divideIntervalValues (N 0)       NegativeInf = N 0 
divideIntervalValues (N 0)       PositiveInf = N 0
divideIntervalValues (N x)       PositiveInf = N 0
divideIntervalValues (N x)       NegativeInf = N 0
divideIntervalValues PositiveInf PositiveInf = N 0 -- non-standard: for compatibility with mult 
divideIntervalValues NegativeInf NegativeInf = N 0 
divideIntervalValues NegativeInf PositiveInf = N 0 
divideIntervalValues PositiveInf NegativeInf = N 0

divideIntervalValues (N x)       (N y)       = N (x `div` y) -- caution