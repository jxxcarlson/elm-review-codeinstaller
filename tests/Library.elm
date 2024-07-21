module Library exposing (..)

import Elm.Syntax.Expression exposing (Expression(..), LetDeclaration(..))
import Elm.Syntax.Infix as Infix
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Pattern exposing (Pattern(..))
import Expect
import Install.Library as Library
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Tests for helper functions" [ testExpressionToString ]


testExpressionToString =
    test "Expression to string" <|
        \() ->
            List.map2 Library.isStringEqualToExpression expectedStrings allExpressions
                |> List.all identity
                |> Expect.equal True


allExpressions : List (Node Expression)
allExpressions =
    [ UnitExpr
    , Application
        [ node_ <| FunctionOrValue [ "Basics" ] "stringFromInt"
        , node_ <| Integer 1
        ]
    , OperatorApplication "+"
        Infix.Left
        (node_ (Integer 1))
        (node_ (Integer 2))
    , FunctionOrValue
        [ "Module" ]
        "foo"
    , IfBlock
        (node_
            (OperatorApplication "=="
                Infix.Left
                (node_ (Integer 1))
                (node_ (Integer 2))
            )
        )
        (node_ (Integer 1))
        (node_ (Integer 2))
    , PrefixOperator "(+)"
    , Operator "+"
    , Integer 1
    , Hex 0x01
    , Floatable 44.5
    , Negation (node_ (FunctionOrValue [] "True"))
    , Literal "foo"
    , CharLiteral 'a'
    , TupledExpression [ node_ (Integer 1), node_ (Integer 2) ]
    , ParenthesizedExpression (node_ (Integer 1))
    , LetExpression
        { declarations =
            [ node_ <|
                LetFunction
                    { documentation = Nothing
                    , signature = Nothing
                    , declaration = node_ { name = node_ "foo", arguments = [], expression = node_ (FunctionOrValue [] "bar") }
                    }
            , node_ <|
                LetFunction
                    { documentation = Nothing
                    , signature = Nothing
                    , declaration = node_ { name = node_ "baz", arguments = [], expression = node_ (Integer 1) }
                    }
            , node_ <|
                LetDestructuring
                    (node_ <| TuplePattern [ node_ <| VarPattern "foo", node_ <| VarPattern "bar" ])
                    (node_ <| FunctionOrValue [] "baz")
            ]
        , expression = node_ (Integer 1)
        }
    , CaseExpression
        { expression = node_ (FunctionOrValue [] "maybeList")
        , cases =
            [ ( node_ <| NamedPattern { moduleName = [], name = "Just" } [ node_ <| ListPattern [] ]
              , node_ (ListExpr [])
              )
            , ( node_ <| NamedPattern { moduleName = [], name = "Just" } [ node_ <| VarPattern "list" ]
              , node_ (FunctionOrValue [] "list")
              )
            , ( node_ <| NamedPattern { moduleName = [], name = "Nothing" } []
              , node_ (ListExpr [])
              )
            ]
        }
    , LambdaExpression
        { args =
            [ node_ <| VarPattern "x"
            , node_ <| VarPattern "y"
            ]
        , expression = node_ (IfBlock (node_ (FunctionOrValue [] "someCondition")) (node_ (FunctionOrValue [] "x")) (node_ (FunctionOrValue [] "y")))
        }
    , RecordExpr
        [ node_ <| ( node_ "name", node_ <| Literal "foo" )
        , node_ <| ( node_ "age", node_ <| Integer 1 )
        ]
    , ListExpr
        [ node_ <|
            RecordExpr
                [ node_ <| ( node_ "name", node_ <| Literal "foo" )
                , node_ <| ( node_ "age", node_ <| Integer 1 )
                ]
        , node_ <|
            RecordExpr
                [ node_ <| ( node_ "name", node_ <| Literal "bar" )
                , node_ <| ( node_ "age", node_ <| Integer 2 )
                ]
        ]
    , RecordAccess
        (node_ <| ParenthesizedExpression (node_ <| Application [ node_ <| FunctionOrValue [] "getFoo" ]))
        (node_ "name")
    , RecordAccessFunction "name"
    , RecordUpdateExpression (node_ "a") [ node_ <| ( node_ "name", node_ <| Literal "bar" ) ]
    , GLSLExpression "foo"
    ]
        |> List.map node_


expectedStrings : List String
expectedStrings =
    let
        ifExpression =
            "if 1 == 2 then\n                1\n            else\n                2"

        letInExpression =
            "let\n                foo = bar\n                baz = 1\n                (foo, bar) = baz\n            in\n            1"

        caseExpression =
            "case maybeList of\n                Just [] -> []\n                Just list -> list\n                Nothing -> []\n            "

        lambdaExpression =
            "\\x y -> if someCondition then\n                        x\n                    else\n                        y"
    in
    [ "()"
    , "Basics.stringFromInt 1"
    , "1 + 2"
    , "Module.foo"
    , ifExpression
    , "(+)"
    , "+"
    , "1"
    , "0x1"
    , "44.5"
    , "not True"
    , "\"foo\""
    , "'a'"
    , "(1, 2)"
    , "(1)"
    , letInExpression
    , caseExpression
    , lambdaExpression
    , "{name = \"foo\", age = 1}"
    , "[{name = \"foo\", age = 1}, {name = \"bar\", age = 2}]"
    , "(getFoo).name"
    , ".name"
    , "{a | name = \"bar\"}"
    , "foo"
    ]


node_ : a -> Node a
node_ a =
    Node.empty a
