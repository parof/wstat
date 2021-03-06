import Test.Tasty
import Test.Tasty.HUnit

-- import Test.Tasty
-- import Test.Tasty.HUnit

import StmtParseSpec
import WhileProgramSpec
import NonDetSpec
import EquationBasedSpec

main :: IO ()
main = do
  defaultMain (testGroup "Library tests" tests)
    where
      tests = WhileProgramSpec.tests
              ++ StmtParseSpec.tests
              ++ NonDetSpec.tests
              ++ EquationBasedSpec.tests
              -- ++ WideningPointsSpec.tests
