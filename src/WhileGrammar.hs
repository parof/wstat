module WhileGrammar
( Stmt (
    Seq,
    Assign,
    If,
    While,
    Repeat,
    For,
    Skip,
    Assert),
  BExpr (..),
  BBooleanBinOperator (..),
  BArithmeticBinOperator (..),
  AExpr (..),
  AArithemticBinOperator (..),
  Atomic (..),
  assign2atomic,
  bexpr2atomic
)
where

-------------------------------------------------------------------------------
--                                 GRAMMAR
-------------------------------------------------------------------------------

data Stmt = Seq Stmt Stmt
          | Assign String AExpr
          | If BExpr Stmt Stmt
          | While BExpr Stmt
          | Skip
          | Assert BExpr
          -- Sugar
          | Repeat Stmt BExpr -- not used
          | For String AExpr AExpr Stmt -- not used
          deriving (Show,Eq)

data BExpr = BoolConst Bool -- not used
           | Not BExpr -- Sugar with De Morgan rules
           | BooleanBinary    BBooleanBinOperator    BExpr BExpr
           | ArithmeticBinary BArithmeticBinOperator AExpr AExpr -- not used
           | ArithmeticUnary  BArithmeticBinOperator AExpr -- not parsed
           deriving (Show,Eq)

data BBooleanBinOperator = And
                         -- Sugar
                         | Or
                         deriving (Show,Eq)

data BArithmeticBinOperator = LessEq
                            | IsEqual
                            -- Sugar
                            | IsNEqual
                            | Less
                            | Greater
                            | GreaterEq
                            deriving (Show,Eq)

-- TODO: IntConst should be a singleton NonDet
data AExpr = Var      String
           | IntConst Integer -- not used
           | Neg      AExpr
           | ABinary  AArithemticBinOperator AExpr AExpr
           | NonDet   Integer Integer
          --  Sugar
           | Exp      AExpr Integer -- not used
           deriving (Show,Eq)

data AArithemticBinOperator = Add
                            | Subtract
                            | Multiply
                            | Division
                            deriving (Show,Eq)

-- equational based semantic

data Atomic = AAssign String AExpr -- atomic asignement statement
            | AUnaryCond BArithmeticBinOperator AExpr -- Atomic Unary Condition operator
            deriving Show

assign2atomic :: Stmt -> Atomic
assign2atomic (Assign var expr) = AAssign var expr

bexpr2atomic :: BExpr -> Atomic
bexpr2atomic (ArithmeticUnary op expr) = AUnaryCond op expr
bexpr2atomic (Not expr) = bexpr2atomic expr -- TODO: deve rispettare De Morgan