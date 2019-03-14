module Interfaces.CompleteLattice where

--------------------------------------------------------------------------------
--                               Complete Lattice
--------------------------------------------------------------------------------

class Eq p => CompleteLattice p where

    subset :: p -> p -> Bool -- not comparable elements return False

    top :: p
    top = error "[CompleteLattice] Top is not needed"

    bottom :: p

    join :: p -> p -> p

    meet :: p -> p -> p

    widen :: p -> p -> p

    -- auxiliary functions

    isBottom :: p -> Bool
    isBottom v = v `subset` bottom