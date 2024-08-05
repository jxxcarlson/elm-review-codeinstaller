module Install.FieldInTypeAliasTest exposing (..)

import Install
import Install.FieldInTypeAlias
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.FieldInTypeAlias"
        [ Run.expectNoErrorsTest_ test1.description test1.src test1.installation
        , Run.testFix_ test2
        , Run.testFix_ test3
        , Run.testFix_ test4
        ]


test1 =
    { description = "should not report an error when the field already exists"
    , src = """module Client exposing (..)

type alias Client =
    { name : String
    , age : Int
    }"""
    , installation =
        Install.FieldInTypeAlias.config "Client" "Client" [ "name : String" ]
            |> Install.insertFieldInTypeAlias
    }


test2 =
    { description = "should report an error when the field does not exist"
    , src = """module Client exposing (..)

type alias Client =
    { age : Int
    }"""
    , installation =
        Install.FieldInTypeAlias.config "Client" "Client" [ "name : String" ]
            |> Install.insertFieldInTypeAlias
    , under = """type alias Client =
    { age : Int
    }"""
    , fixed = """module Client exposing (..)

type alias Client =
    { age : Int
    , name : String
    }"""
    , message = "Add name to Client"
    }


test3 =
    { description = "should report an error when the field does not exist in a nested module"
    , src = """module Data.Client exposing (..)
type alias Client =
    { age : Int
    }"""
    , installation =
        Install.FieldInTypeAlias.config "Data.Client" "Client" [ "name : String" ]
            |> Install.insertFieldInTypeAlias
    , under = """type alias Client =
    { age : Int
    }"""
    , fixed = """module Data.Client exposing (..)
type alias Client =
    { age : Int
    , name : String
    }"""
    , message = "Add name to Client"
    }



-- Test 4: should add multiple fields


test4 =
    { description = "should add multiple fields"
    , src = """module Client exposing (..)
type alias Client =
    { age : Int
    }"""
    , installation =
        Install.FieldInTypeAlias.config "Client" "Client" [ "name : String", "email : String", "age : Int", "lastName : String", "favoriteColor : String" ]
            |> Install.insertFieldInTypeAlias
    , under = """type alias Client =
    { age : Int
    }"""
    , fixed = """module Client exposing (..)
type alias Client =
    { age : Int
    , name : String
    , email : String
    , lastName : String
    , favoriteColor : String
    }"""
    , message = "Add fields email, favoriteColor, lastName, name to Client"
    }
