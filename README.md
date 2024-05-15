# Elm-review-install-code

May 14, 2024

This aim of this project is to write a set of elm-review rules
which make it easy to add new abilities to an existing Elm app.

Consider, for example, the "magic-token" authentification
system for Lamdera apps at [jxxcarlson/kitchen-sink](https://github.com/jxxcarlson/kitchen-sink).
While the code from this app can be extracted by hand and implanted
in another app, that process is laborious, time-consuming, and
utterly routine. In other words, it is a task best carried out by a 
computer program. Hence this package.

The project is still in development, so expect it to change a lot
over the next weeks and likely months.  Consider it an experiment.

To test the review code in its current state, try running this in 
a clean Lamdera project:

```
npx elm-review --template jxxcarlson/elm-review-install-code/example
```

A total of five changes should be made to the Lamdera code in `src`.

See the comments at the top of `Install/ClauseInCase.elm` for
more information.

