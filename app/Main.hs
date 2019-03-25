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
    putStrLn "=================================Program"
    print $ parse input

    putStr $ "> Pick a domain in ["++ listAllDomains ++"]: "
    hFlush stdout
    chosenDomain <- getLine

    runAnalysis chosenDomain (parse input)

runAnalysis :: String -> Stmt -> IO ()
runAnalysis domain abstractSyntaxTree = do
    let wideningPoints = buildWideningPoints abstractSyntaxTree in
        case domain of
            "ss" -> runSimpleSignDomainAnalysis abstractSyntaxTree wideningPoints
            "s"  -> runSignDomainAnalysis abstractSyntaxTree wideningPoints
            "i"  -> runIntervalDomainAnalysis abstractSyntaxTree wideningPoints
            _    -> putStrLn ("Unknown domain " ++ show domain)

runSimpleSignDomainAnalysis:: Stmt -> [Label] -> IO ()
runSimpleSignDomainAnalysis abstractSyntaxTree wideningPoints = do
    putStr $ prettyPrint abstractSyntaxTree programPoints
    return ()
    where controlFlowGraph = buildCfg abstractSyntaxTree
          programPoints = fixpoint controlFlowGraph wideningPoints (buildInitialSimpleSignState abstractSyntaxTree)

runSignDomainAnalysis :: Stmt -> [Label] -> IO ()
runSignDomainAnalysis abstractSyntaxTree wideningPoints = do
    putStr $ prettyPrint abstractSyntaxTree programPoints
    return ()
    where controlFlowGraph = buildCfg abstractSyntaxTree
          programPoints = fixpoint controlFlowGraph wideningPoints (buildInitialSignState abstractSyntaxTree)

runIntervalDomainAnalysis :: Stmt -> [Label] -> IO ()
runIntervalDomainAnalysis abstractSyntaxTree wideningPoints = do
    putStr $ prettyPrint abstractSyntaxTree programPoints
    return ()
    where controlFlowGraph = buildCfg abstractSyntaxTree
          programPoints = fixpoint controlFlowGraph wideningPoints (buildInitialIntervalState abstractSyntaxTree)
