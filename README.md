# elm-review-codeinstaller

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to REPLACEME.

## Provided rules

- [`Install.ClauseInCase`](https://package.elm-lang.org/packages/jxxcarlson/elm-review-codeinstaller/1.0.0/Install-ClauseInCase) - Reports REPLACEME.

## Configuration

```elm
module ReviewConfig exposing (config)

import Install.ClauseInCase
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ Install.ClauseInCase.rule
    ]
```

## Try it out

You can try the example configuration above out by running the following command:

```bash
elm-review --template jxxcarlson/elm-review-codeinstaller/example
```
