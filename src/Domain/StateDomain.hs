{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}

module Domain.StateDomain where

import Data.Map                       (Map, insert, fromList, (!), keys)
import Interfaces.State as S          (State(..))
import Interfaces.CompleteLattice     (bottom)
import Interfaces.AbstractValueDomain (AVD)
import WhileGrammar                   (V)

--------------------------------------------------------------------------------
-- State Domain data type
--------------------------------------------------------------------------------

data SD v b = SD (Map v b)
            | Bottom
            deriving (Show)

--------------------------------------------------------------------------------
-- SD is a State, whether b is AVD
--------------------------------------------------------------------------------

instance AVD b => State SD V b where

    lookup _ Bottom = bottom
    lookup var (SD x) = x ! var

    update _ _ Bottom = Bottom -- TODO: is correct?
    update var value (SD x) = SD $ insert var value x

    fromList = SD . Data.Map.fromList

--------------------------------------------------------------------------------
-- usefull auxiliary functions
--------------------------------------------------------------------------------

{--
function that propagate alternatives to bottom,
    as described in the first two pattern match lines
take a function f and two SDs as params
apply f two the internal maps and then wrap the results
--}
unit :: AVD b => (b -> b -> b) -> SD V b -> SD V b -> SD V b
unit _ Bottom y = y
unit _ x Bottom = x
unit f (SD x) (SD y) = mergeWithFunction f x y

{--
take a function f and two Maps as params
apply f two the maps for each keys
note that the two maps has the same keys as precondition
--}
mergeWithFunction :: (State s k v, Ord k) =>
                     (a -> t -> v) -> Map k a -> Map k t -> s k v
mergeWithFunction f x y = S.fromList $
    zip (keys x) (fmap (applyFunction f x y) (keys x))

{--
take a function f and two Maps as params and then a single key
apply f two the relative value extracted using the passed key
note that the two maps has the same keys as precondition
--}
applyFunction :: Ord k => (a -> b -> c) -> Map k a -> Map k b -> k -> c
applyFunction f x y = \var -> f (x ! var) (y ! var)