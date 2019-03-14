module Interfaces.AbstractValueDomain where

import WhileGrammar
import Interfaces.CompleteLattice

--------------------------------------------------------------------------------
--                            Abstract Value Domain
--------------------------------------------------------------------------------

-- b is a powerset of abstract values
class CompleteLattice b => AVD b where

    -- given a constant in the concrete domain abstracts it to an abstract value
    cons :: I -> b

    -- given a random generator [n1,n2] abstracts it to an abstract value
    rand :: SignedInfiniteInteger -> SignedInfiniteInteger -> b

    -- given an arithmetic unary operator applies it to an abstract value
    unary :: AArithemticUnaryOperator -> b -> b

    -- given an arithmetic binary operator applies it to two abstract values
    binary :: AArithemticBinOperator -> b -> b  -> b
