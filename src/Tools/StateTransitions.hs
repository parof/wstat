module Tools.StateTransitions where

--------------------------------------------------------------------------------
--                        State Transition Monad
--------------------------------------------------------------------------------
-- 
-- This module is used to building the CFG of the abstract syntax tree in 
-- using the cabalities of the monads.
-- 

newtype ST a = ST (Integer -> (a, Integer))

applyST :: ST a -> Integer -> (a, Integer)
applyST (ST st) s = st s

instance Functor ST where
    fmap f st = do s <- st
                   return (f s)

instance Applicative ST where
    pure = return
    stf <*> stx = do f <- stf
                     x <- stx
                     return (f x)

instance Monad ST where
    return x = ST (\s -> (x, s))
    stx >>= f = ST (\s -> let (x, s') = applyST stx s in applyST (f x) s')