# elm-review-codeinstaller

Package designed to make it easy to add pieces of code to an existing codebase using `elm-review` rules. This package provides a set of tools to help you automatically insert clauses in case expressions, fields in type aliases, fields in initializer functions, and variants in custom types.

The project is still in development, so expect it to change a lot over the next weeks and likely months.  Consider it an experiment.

## Installation
To install `elm-review-codeinstaller`, add it to your `elm.json` dependencies:

```bash
elm install jxxcarlson/elm-review-codeinstaller
```

## Usage
Suppose you have the following `Msg` type and `update` function in your `Counter` module:

```elm
module Counter exposing (..)

type Msg
    = Increment
    | Decrement

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, Cmd.none)

        Decrement ->
            ( { model | counter = model.counter - 1 }, Cmd.none)
```

To add a new `ResetCounter` variant to the `Msg` type and handle it in the `update` function, your `ReviewConfig.elm` file would look like the following:

```elm
module ReviewConfig exposing (config)

import Install.ClauseInCase
import Install.TypeVariant
import Review.Rule exposing (Rule)

config : List Rule
config =
    addResetCounter ++
    [ -- other rules
    ]

addResetCounter : List Rule
addResetCounter =
    [ addResetCounterVariant
    , addResetCounterClause
    ]

addResetCounterVariant : Rule
addResetCounterVariant =
    Install.TypeVariant.makeRule "Msg" "Msg" "ResetCounter"

addResetCounterClause : Rule
addResetCounterClause =
    Install.ClauseInCase.init "Counter" "update" "ResetCounter" "( { model | counter = 0 }, Cmd.none )"
        |> Install.ClauseInCase.makeRule
```

After running `elm-review --fix`, your `Counter` module will be updated as follows:

```elm
module Counter exposing (..)

type Msg
    = Increment
    | Decrement
    | ResetCounter

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, Cmd.none ) 

        Decrement ->
            ( { model | counter = model.counter - 1 },  Cmd.none )

        ResetCounter ->
            ( { model | counter = 0 }, Cmd.none )
```
## Modules

`elm-review-codeinstaller` includes the following modules:

- **Install.ClauseInCase**: Add a clause to a case expression in a specified function within a specified module. For more details, see the [docs](https://package.elm-lang.org/packages/jxxcarlson/elm-review-codeinstaller/latest/Install-ClauseInCase).
- **Install.FieldInTypeAlias**: Add a field to a specified type alias in a specified module. For more details, see the [docs](https://package.elm-lang.org/packages/jxxcarlson/elm-review-codeinstaller/latest/Install-FieldInTypeAlias).
- **Install.Initializer**: Add a field to the body of an initializer function where the return value is of the form `( Model, Cmd msg )`. For more details, see the [docs](https://package.elm-lang.org/packages/jxxcarlson/elm-review-codeinstaller/latest/Install-Initializer).
- **Install.TypeVariant**: Add a variant to a specified type in a specified module. For more details, see the [docs](https://package.elm-lang.org/packages/jxxcarlson/elm-review-codeinstaller/latest/Install-TypeVariant).

## Try it out
To test the review code in its current state, try running this in a clean Lamdera project:

```
npx elm-review --template jxxcarlson/elm-review-install-code/example
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you have any improvements or bug fixes.

## Contributors

James Carlson and Mateus Leite.

## License

This package is licensed under the MIT License.
