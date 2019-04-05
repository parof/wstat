# wstat

[![CircleCI](https://circleci.com/gh/parof/wstat.svg?style=svg)](https://circleci.com/gh/parof/wstat) [![Generic badge](https://img.shields.io/badge/sound-yes-<COLOR>.svg)](https://en.wikipedia.org/wiki/Soundness)


Wstat is a statical analyzer for the _While_ toy language. It relies on [Abstract Interpretation](https://en.wikipedia.org/wiki/Abstract_interpretation) for run a _sound_ analysis.

* [While Language](#while-language)
* [About abstract interpretation](#about-abstract-interpretation)
* [Installation](#installation)

## While Language ##

The syntax of the While language is given by the following grammar.

```haskell
Stmt  : Var := AExpr
      | Stmt ; Stmt
      | skip
      | if BExpr then Stmt else Stmt endif
      | while BExpr do Stmt done

AExpr : ( AExpr )
      | Int
      | Var
      | AExpr + AExpr
      | AExpr - AExpr
      | AExpr * AExpr
      | AExpr / AExpr
      | [Int   , Int]
      | [neginf, Int]
      | [Int   , posinf]
      | [neginf, posinf]

BExpr : ( BExpr )
      | Bool
      | not BExpr
      | BExpr and BExpr
      | BExpr or  BExpr
      | AExpr !=  AExpr
      | AExpr  =  AExpr
      | AExpr <=  AExpr
      | AExpr >=  AExpr
      | AExpr  <  AExpr
      | AExpr  >  AExpr

Var   : [a-z][a-zA-Z]*
Int   : [1-9][0-9]*
Bool  : true | false
```

One can include comments surrounding them in `#`s

### Examples

```python
x := 0;
while x < 40 do
    x := (x + 1)
done
```

```python
x := [0, posinf]; # nondeterministic choice #
if (x <= 10) then
    y := 1
else 
    y := 0
endif
```

```python
x := 0;
y := 1;
while true do
    y := y + 1
done
```

## About abstract interpretation

The `wstat` tool is based on _abstract interpretation_. It analyzes a source program code and infers _sound invariants_. You can choose between three different [abstract domains](https://en.wikipedia.org/wiki/Abstract_interpretation#Examples_of_abstract_domains):

- **Simple Sign Domain**: 

![Simple sign Domain](img/simpleSignDomain.png  "Simple sign Domain")
- **Sign Domain**: 

![Sign domain](img/signDomain.png "Sign domain")
- **Interval Domain**: 

![Interval domain](img/intervalDomain.png "Interval domain")

Here you can see some example of results using the interval domain:

![Interval analysis on terminating program](img/analysis1.png "Interval analysis on terminating program")

![Interval analysis on non-terminating program](img/analysis2.png "Interval analysis on non-terminating program")

![Interval analysis on division by zero](img/analysis3.png "Interval analysis on division by zero")

### Adding a new Concrete non-relational domain

It is possible to implement a new non-relational abstract domain and plug it in wstat:

1. Build the (non-relational) domain, add the new module in the ```src/Domains``` directory
2. Add the new domain's name in the `Domains.DomainsList` module
3. Add the corresponding initial-state builder in the `InitialStateBuilder` module
4. Add in the main the procedure to run the analysis instantiated with the relative initial-state builder

## Installation

### Installation prerequisites

- [Stack](https://docs.haskellstack.org/en/stable/README/) (version 1.7.1 or newer)

On Unix System install as:
```bash
curl -sSL https://get.haskellstack.org/ | sh
```
Or
```bash
wget -qO- https://get.haskellstack.org/ | sh
```

### Get Started

Before the first use build dependecies:
```bash
./init
```

Build the project:
```bash
./build
```

Test the project:
```bash
./spec
```

Run the project:
```bash
./run
```