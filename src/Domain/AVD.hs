module Domain.AVD where

import WhileGrammar

-- Abstract Value Domain
-- b is a powerset of abstract values
class AVD b where
    -- <= relation
    subset :: b -> b -> Bool

    top :: b

    bottom :: b

    cons :: I -> b

    rand :: SignedInfiniteInteger -> SignedInfiniteInteger -> b

    unary :: AArithemticUnaryOperator -> b -> b

    binary :: AArithemticBinOperator -> b -> b  -> b

    join :: b -> b -> b

    meet :: b -> b -> b

    widen :: b -> b -> b

    isBottom :: b -> Bool
    isBottom v = v `subset` bottom

    -- e possibile aggiungere le funzioni per inferire automaticamente la funzione C