git checkout counter/src
elm-format --yes counter/src
npx elm-review --config preview counter/src --debug --fix-all
