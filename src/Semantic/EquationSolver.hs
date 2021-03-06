{-# LANGUAGE FlexibleContexts #-}

module Semantic.EquationSolver where

import Interfaces.AbstractStateDomain
import Interfaces.AbstractDomain
import Interfaces.State
import SyntacticStructure.ControlFlowGraph
import Tools.StateTransitions
import SyntacticStructure.ProgramPoints

type ProgramPointState  st = (Label, st)
type ProgramPointsState st = [ProgramPointState st]

analyze :: (AbstractStateDomain (s k v), State s k v, AbstractDomain v) =>
     ControlFlowGraph (s k v -> s k v) ->
     [Label] ->
     s k v ->
     ProgramPointsState (s k v)
analyze cfg wideningPoints initialState =
    applyNarrowing cfg wideningPoints initialState forwardAnalysisResult
    where forwardAnalysisResult = forwardAnalysis cfg wideningPoints initialState

-- finds the fixpoint of the system of equations induced by the cfg and returns
-- one abstract state for every program point.
forwardAnalysis :: (AbstractStateDomain (s k v), State s k v, AbstractDomain v) =>
    ControlFlowGraph (s k v -> s k v) -> -- cfg
    [Label] ->                           -- program points
    s k v ->                             -- inital state
    ProgramPointsState (s k v)
forwardAnalysis cfg wideningPoints initialState =
    fixpoint cfg wideningPoints initialState initialProgramPointsStates widen
        where programPoints = getProgramPoints cfg
              variables     = getVars initialState
              initialProgramPointsStates = [ (p, bottomState variables) | p <- programPoints]

applyNarrowing :: AbstractStateDomain d =>
    ControlFlowGraph (d -> d) ->
    [Label] ->              -- narrowing points
    d ->                    -- initial state
    ProgramPointsState d -> -- analysis result
    ProgramPointsState d
applyNarrowing cfg narrowingPoints initialState analysisResult =
    fixpoint cfg narrowingPoints initialState analysisResult narrow

fixpoint :: AbstractStateDomain d =>
    ControlFlowGraph (d -> d) ->
    [Label] ->              -- narrowing points
    d ->                    -- initial state
    ProgramPointsState d -> -- analysis result
    (d -> d -> d) ->        -- narrow or widen operator
    ProgramPointsState d
fixpoint cfg wideningPoints initialState firstColumn operator =
    extractFixpoint [ systemResolver cfg wideningPoints i operator initialState firstColumn | i <- [0..]]

-- selects the first two equal states: the fixpoint
extractFixpoint :: Eq a => [a] -> a
extractFixpoint (x:y:xs) | x == y    = x
                         | otherwise = extractFixpoint (y:xs)

-- resolves the system of equations induced by the cfg at the nth iteration
systemResolver :: AbstractStateDomain d =>
    ControlFlowGraph (d -> d) ->
    [Label] ->               -- widening or narrowing points
    Int ->                   -- nth iteration
    (d -> d -> d) ->         -- widen or narrow operator
    d ->                     -- initial state
    ProgramPointsState d ->  -- first column of the analysis, base case
    ProgramPointsState d
systemResolver cfg wideningPoints i op initialState firstColumn =
    [(programPoint, iterationResolver programPoint cfg wideningPoints i op initialState firstColumn)
        | programPoint <- getProgramPoints cfg]

-- calculates the state of one program point at the nth iteration
iterationResolver :: AbstractStateDomain d =>
    Label ->                      -- program point
    ControlFlowGraph (d -> d) ->  -- cfg
    [Label] ->                    -- widening points
    Int ->                        -- nth iteration
    (d -> d -> d) ->              -- widening or narrowing operator
    d ->                          -- initial state
    ProgramPointsState d ->       -- analysis result
    d                             -- new state for the point
iterationResolver j _ _ 0 _ _ firstColumn = retrieveProgramPointState firstColumn j -- first iteration
iterationResolver 1 _ _ _ _ initialState firstColumn = initialState -- first program point
iterationResolver j cfg wideningPoints k op initialState firstColumn
        | j `elem` wideningPoints = oldState `op` newState -- op == widen or narrow
        | otherwise = newState
    where
        entryProgramPoints = retrieveEntryLabels j cfg
        oldState = iterationResolver j cfg wideningPoints (k-1) op initialState firstColumn
        newState = foldr join bottom 
            [ f $ iterationResolver i cfg wideningPoints (k-1) op initialState firstColumn
                | (i, f) <- entryProgramPoints ]

-- given a label and the entire cfg returns the entry label for each cfg-entries
-- that has as final label the given label
retrieveEntryLabels :: Label -> ControlFlowGraph a -> ProgramPointsState a
retrieveEntryLabels label cfg =
    [(initial, f) | (initial, f, final) <- cfg, final == label]


retrieveProgramPointState :: ProgramPointsState a -> Label -> a
retrieveProgramPointState [] label = error ("No program point " ++ show label ++ " found")
retrieveProgramPointState ((l, ctx):pps) label | label == l = ctx
                                               | otherwise  = retrieveProgramPointState pps label