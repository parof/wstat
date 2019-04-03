module Main where

import Domains.SignDomain
import Domains.SimpleSignDomain
import Domains.IntervalDomain
import Domains.DomainsList
import Interfaces.AbstractStateDomain
import Semantic.EquationSolver
import SyntacticStructure.ControlFlowGraph
import SyntacticStructure.InitialStateBuilder
import SyntacticStructure.Parser
import SyntacticStructure.ProgramPoints
import SyntacticStructure.WhileGrammar
import System.IO
import Tools.Utilities
import SyntacticStructure.PrettyPrinter


main :: IO ()
main = do
    input <- readInput
    -- putStrLn "=================================Program"
    -- print $ parse input

    putStr $ "> Pick a domain in ["++ listAllDomains ++"]: "
    hFlush stdout
    chosenDomain <- getLine

    runAnalysis chosenDomain (parse input)

runAnalysis :: String -> Stmt -> IO ()
runAnalysis domain abstractSyntaxTree = do
    let wideningPoints = buildWideningPoints abstractSyntaxTree in
        case domain of
            "ss" -> runSimpleSignDomainAnalysis abstractSyntaxTree wideningPoints
            "s"  -> runSignDomainAnalysis       abstractSyntaxTree wideningPoints
            "i"  -> runIntervalDomainAnalysis   abstractSyntaxTree wideningPoints
            _    -> putStrLn ("Unknown domain " ++ show domain)

runSimpleSignDomainAnalysis:: Stmt -> [Label] -> IO ()
runSimpleSignDomainAnalysis abstractSyntaxTree wideningPoints = do
    userState <- readInitialState readInitialSimpleSignState
    print userState
    hFlush stdout
    putStr $ prettyPrint abstractSyntaxTree analysisResult
    where controlFlowGraph = buildCfg abstractSyntaxTree
          initialState     = buildInitialSimpleSignState abstractSyntaxTree
          analysisResult   = forwardAnalysis controlFlowGraph wideningPoints initialState

runSignDomainAnalysis :: Stmt -> [Label] -> IO ()
runSignDomainAnalysis abstractSyntaxTree wideningPoints = do
    userState <- readInitialState readInitialSignState
    print userState
    hFlush stdout
    putStr $ prettyPrint abstractSyntaxTree analysisResult
    where controlFlowGraph = buildCfg abstractSyntaxTree
          initialState     = buildInitialSignState abstractSyntaxTree
          analysisResult   = forwardAnalysis controlFlowGraph wideningPoints initialState

runIntervalDomainAnalysis :: Stmt -> [Label] -> IO ()
runIntervalDomainAnalysis abstractSyntaxTree wideningPoints = do
    userState <- readInitialState readInitialIntervalState
    putStr "> State: "
    print userState
    hFlush stdout
    putStr $ prettyPrint abstractSyntaxTree analysisResult
    where controlFlowGraph = buildCfg abstractSyntaxTree
          initialState     = buildInitialIntervalState abstractSyntaxTree
          analysisResult   = forwardAnalysis controlFlowGraph wideningPoints initialState

readInitialState :: IO d -> IO d
readInitialState reader = do putStrLn "> Insert initial map (just return to complete the process):"
                             userState <- reader
                             return userState
